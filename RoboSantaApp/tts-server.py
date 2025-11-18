import contextlib
import io
import json
import logging
import os
import sys
import unicodedata
import warnings
from http.server import BaseHTTPRequestHandler, HTTPServer

import torch
import torchaudio as ta

os.environ["TQDM_DISABLE"] = "1"
from transformers.utils import logging as hf_logging
from diffusers.utils import logging as df_logging

hf_logging.set_verbosity_error()
df_logging.set_verbosity_error()
warnings.filterwarnings("ignore", category=FutureWarning)
warnings.filterwarnings(
    "ignore",
    r"pkg_resources is deprecated.*",
    category=UserWarning,
    module=r"perth\.perth_net",
)
logging.getLogger("chatterbox").setLevel(logging.ERROR)

# Force CPU mapping for any torch.load inside the library
_real_torch_load = torch.load


def _torch_load_cpu(*args, **kw):
    kw.setdefault("map_location", "cpu")
    return _real_torch_load(*args, **kw)


torch.load = _torch_load_cpu


def _load_tts():
    stdout_buf, stderr_buf = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(stdout_buf), contextlib.redirect_stderr(stderr_buf), warnings.catch_warnings():
        warnings.filterwarnings(
            "ignore",
            r"pkg_resources is deprecated.*",
            category=UserWarning,
            module=r"perth\.perth_net",
        )
        from chatterbox.mtl_tts import ChatterboxMultilingualTTS

        device = "mps" if torch.backends.mps.is_available() else "cpu"
        return ChatterboxMultilingualTTS.from_pretrained(device=torch.device(device))


tts = _load_tts()


def synthesize_to_file(output_path: str, voice: str, text: str) -> None:
    normalized_text = unicodedata.normalize("NFKD", text or "")
    if not normalized_text.strip():
        raise ValueError("Text is empty after normalization")

    prompt_path = os.path.join("Voices", voice)
    if not os.path.exists(prompt_path):
        raise FileNotFoundError(f"Voice prompt not found: {prompt_path}")

    stdout_buf, stderr_buf = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(stdout_buf), contextlib.redirect_stderr(stderr_buf), warnings.catch_warnings():
        warnings.filterwarnings(
            "ignore",
            r"pkg_resources is deprecated.*",
            category=UserWarning,
            module=r"perth\.perth_net",
        )
        wav = tts.generate(
            normalized_text,
            language_id="sv",
            audio_prompt_path=prompt_path,
            temperature=0.1,
            exaggeration=0.1,
            cfg_weight=0.1,
        )

    directory = os.path.dirname(output_path)
    if directory:
        os.makedirs(directory, exist_ok=True)
    ta.save(output_path, wav, tts.sr)


class TTSServerHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_POST(self):
        content_length = self.headers.get("Content-Length")
        if content_length is None:
            self.send_error(411, "Content-Length header required")
            return

        try:
            length = int(content_length)
        except ValueError:
            self.send_error(400, "Invalid Content-Length header")
            return

        body = self.rfile.read(length)
        try:
            payload = json.loads(body.decode("utf-8"))
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON payload")
            return

        output_path = payload.get("file")
        voice = payload.get("voice")
        text = payload.get("text")
        if not output_path or not voice or text is None:
            self.send_error(400, "Payload must include file, voice, and text")
            return

        try:
            synthesize_to_file(output_path, voice, text)
        except FileNotFoundError as exc:
            self.send_error(400, str(exc))
            return
        except Exception as exc:
            print(f"TTS generation failed: {exc}", file=sys.stderr)
            self.send_error(500, "TTS generation failed")
            return

        self.send_response(200)
        response_body = b"OK"
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(response_body)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(response_body)
        self.wfile.flush()


def main():
    server = HTTPServer(("127.0.0.1", 8080), TTSServerHandler)
    print("TTS server listening on http://127.0.0.1:8080", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
