import os, sys, io, contextlib, warnings, unicodedata, torch, torchaudio as ta
os.environ["TQDM_DISABLE"]="1"
from transformers.utils import logging as hf_logging
from diffusers.utils import logging as df_logging
hf_logging.set_verbosity_error(); df_logging.set_verbosity_error()
warnings.filterwarnings("ignore", category=FutureWarning)

# Force CPU mapping for any torch.load inside the library
_real_torch_load = torch.load
def _torch_load_cpu(*args, **kw):
    kw.setdefault("map_location", "cpu")
    return _real_torch_load(*args, **kw)
torch.load = _torch_load_cpu

buf = io.StringIO()
with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf), warnings.catch_warnings():
    warnings.filterwarnings("ignore", r"pkg_resources is deprecated.*", category=UserWarning, module=r"perth\.perth_net")
    from chatterbox.mtl_tts import ChatterboxMultilingualTTS
    device = "mps" if torch.backends.mps.is_available() else "cpu"
    tts = ChatterboxMultilingualTTS.from_pretrained(device=torch.device(device))

    wav = tts.generate(
      unicodedata.normalize('NFKD', sys.argv[3]),
      language_id="sv",
      audio_prompt_path="Voices/" + sys.argv[2],
      temperature=0.1,
      exaggeration=0.1,
      cfg_weight=0.1
      )

ta.save(sys.argv[1], wav, tts.sr)
