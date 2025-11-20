import contextlib
import io
import json
import logging
import os
import re
import sys
import unicodedata
import uuid
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


# Directory for temporary WAV files
TEMP_DIR = "/tmp/tts-server"


def sanitize_voice(voice: str) -> str:
    """Sanitize voice parameter to allow only alphanumeric characters.
    
    Args:
        voice: Raw voice parameter from request
        
    Returns:
        Sanitized voice name
        
    Raises:
        ValueError: If voice contains invalid characters or is empty
    """
    if not voice:
        raise ValueError("Voice parameter is required")
    
    # Remove .wav suffix if present
    if voice.lower().endswith(".wav"):
        voice = voice[:-4]
    
    # Only allow alphanumeric characters
    if not re.match(r'^[A-Za-z0-9]+$', voice):
        raise ValueError("Voice must contain only alphanumeric characters")
    
    return voice


def sanitize_uuid(uuid_str: str) -> str:
    """Sanitize UUID parameter to ensure it's a valid UUID format.
    
    Args:
        uuid_str: Raw UUID string from request
        
    Returns:
        Sanitized UUID string
        
    Raises:
        ValueError: If UUID format is invalid
    """
    if not uuid_str:
        raise ValueError("UUID parameter is required")
    
    # Only allow valid UUID format (hexadecimal with hyphens)
    if not re.match(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', uuid_str.lower()):
        raise ValueError("Invalid UUID format")
    
    return uuid_str.lower()


def synthesize_to_file(output_path: str, voice: str, text: str) -> None:
    """Generate TTS audio and save to file.
    
    Args:
        output_path: Path where WAV file should be saved
        voice: Sanitized voice name (without .wav extension)
        text: Text to synthesize
        
    Raises:
        ValueError: If text is empty after normalization
        FileNotFoundError: If voice prompt file doesn't exist
    """
    normalized_text = unicodedata.normalize("NFKD", text or "")
    if not normalized_text.strip():
        raise ValueError("Text is empty after normalization")

    prompt_path = os.path.join("Voices", f"{voice}.wav")
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

    def do_GET(self):
        # Extract UUID from path (e.g., /uuid or /uuid.wav)
        path = self.path.lstrip("/")
        
        # Remove .wav extension if present
        if path.lower().endswith(".wav"):
            path = path[:-4]
        
        if not path:
            self.send_error(404, "Not Found")
            return
        
        try:
            uuid_str = sanitize_uuid(path)
        except ValueError as exc:
            self.send_error(400, str(exc))
            return
        
        # Check if file exists
        file_path = os.path.join(TEMP_DIR, f"{uuid_str}.wav")
        if not os.path.exists(file_path):
            self.send_error(404, "File not found")
            return
        
        # Read file
        try:
            with open(file_path, "rb") as f:
                file_data = f.read()
        except Exception as exc:
            print(f"Failed to read file {file_path}: {exc}", file=sys.stderr)
            self.send_error(500, "Failed to read file")
            return
        
        # Send file
        self.send_response(200)
        self.send_header("Content-Type", "audio/wav")
        self.send_header("Content-Length", str(len(file_data)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(file_data)
        self.wfile.flush()
        
        # Delete file after successful transfer
        try:
            os.remove(file_path)
        except Exception as exc:
            print(f"Failed to delete file {file_path}: {exc}", file=sys.stderr)

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

        # Extract and validate parameters
        voice = payload.get("voice")
        text = payload.get("text")
        
        if not voice or text is None:
            self.send_error(400, "Payload must include voice and text")
            return
        
        # Sanitize voice parameter
        try:
            sanitized_voice = sanitize_voice(voice)
        except ValueError as exc:
            self.send_error(400, str(exc))
            return
        
        # Generate UUID for output file
        file_uuid = str(uuid.uuid4())
        output_path = os.path.join(TEMP_DIR, f"{file_uuid}.wav")

        try:
            synthesize_to_file(output_path, sanitized_voice, text)
        except FileNotFoundError as exc:
            self.send_error(400, str(exc))
            return
        except ValueError as exc:
            self.send_error(400, str(exc))
            return
        except Exception as exc:
            print(f"TTS generation failed: {exc}", file=sys.stderr)
            self.send_error(500, "TTS generation failed")
            return

        # Return UUID in JSON response
        response_data = {"uuid": file_uuid}
        response_body = json.dumps(response_data).encode("utf-8")
        
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_body)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(response_body)
        self.wfile.flush()


def main():
    # Ensure temp directory exists
    os.makedirs(TEMP_DIR, exist_ok=True)
    
    server = HTTPServer(("127.0.0.1", 8080), TTSServerHandler)
    print("TTS server listening on http://127.0.0.1:8080", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
