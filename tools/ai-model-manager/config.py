import os
from pathlib import Path

# Uses AI_MODELS_ROOT env var if set, otherwise falls back to default
AI_MODELS_ROOT = Path(os.environ.get("AI_MODELS_ROOT", Path.home() / "ComfyUI" / "models"))

# Model type → subfolder mapping.
# The --type argument maps to a destination folder under AI_MODELS_ROOT.
# Where ComfyUI searches multiple folders for one type (e.g. diffusion_models
# searches both unet/ and diffusion_models/), both are listed as separate entries
# so you can target the exact folder you want.
MODEL_TYPE_FOLDERS = {
    # ── Core ComfyUI (from folder_paths.py) ──────────────────────────────
    "checkpoint":           "checkpoints",
    "lora":                 "loras",
    "vae":                  "vae",
    "vae_approx":           "vae_approx",           # TAESD preview decoders
    "unet":                 "unet",                  # } ComfyUI searches both
    "diffusion_models":     "diffusion_models",      # } for diffusion models
    "clip":                 "clip",                  # } ComfyUI searches both
    "text_encoder":         "text_encoders",         # } for text encoders
    "clip_vision":          "clip_vision",
    "controlnet":           "controlnet",            # } ComfyUI searches both
    "t2i_adapter":          "t2i_adapter",           # } for controlnet models
    "embedding":            "embeddings",
    "upscaler":             "upscale_models",
    "latent_upscaler":      "latent_upscale_models",
    "hypernetwork":         "hypernetworks",
    "style_model":          "style_models",          # T2I style adapters
    "gligen":               "gligen",
    "photomaker":           "photomaker",
    "model_patch":          "model_patches",
    "audio_encoder":        "audio_encoders",

    # ── Popular custom node folders ──────────────────────────────────────
    "animatediff":          "animatediff_models",    # AnimateDiff-Evolved
    "ipadapter":            "ipadapter",             # IPAdapter-plus
    "insightface":          "insightface",           # face analysis (IPAdapter, ReActor)
    "facerestore":          "facerestore_models",    # face restoration nodes
    "sams":                 "sams",                  # Segment Anything
    "gguf":                 "gguf",                  # GGUF quantized models
}

# Base model architectures — the compatibility boundary for LoRAs, controlnets, etc.
# Image models
#   sd15        Stable Diffusion 1.5
#   sd2x        Stable Diffusion 2.0 / 2.1
#   sdxl        Stable Diffusion XL
#   sd3         Stable Diffusion 3 / 3.5
#   cascade     Stable Cascade
#   flux        Flux.1 (dev, schnell, etc.)
#   flux2       Flux 2
#   pixart      PixArt Alpha / Sigma
#   auraflow    AuraFlow
#   hunyuandit  HunyuanDiT
#   hunyuanimg  Hunyuan Image 2.1
#   lumina      Lumina Image 2.0
#   hidream     HiDream
#   qwen        Qwen Image
#   chroma      Chroma
#   zimage      Z Image
# Video models
#   svd         Stable Video Diffusion
#   wan         Wan 2.1 / 2.2
#   hunyuanvid  Hunyuan Video
#   ltxv        LTX-Video
#   mochi       Mochi
#   cosmos      Nvidia Cosmos
# Audio models
#   stable_audio  Stable Audio
#   acestep       ACE Step
# Other
#   other       Anything not listed above
BASE_MODELS = [
    "sd15", "sd2x", "sdxl", "sd3", "cascade",
    "flux", "flux2", "pixart", "auraflow",
    "hunyuandit", "hunyuanimg", "lumina", "hidream", "qwen", "chroma", "zimage",
    "svd", "wan", "hunyuanvid", "ltxv", "mochi", "cosmos",
    "stable_audio", "acestep",
    "other",
]

MODEL_EXTENSIONS = {".safetensors", ".ckpt", ".pt", ".pt2", ".pth", ".bin", ".pkl", ".sft", ".gguf"}