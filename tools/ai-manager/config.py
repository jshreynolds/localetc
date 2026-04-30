import os
from pathlib import Path

# Root for all AI models. Two subdirectories: llm/ and comfy/
AI_MODELS_ROOT = Path(os.environ.get("AI_MODELS_ROOT", Path.home() / "ai" / "models"))

# All model file extensions recognized by the tools
MODEL_EXTENSIONS = {".safetensors", ".ckpt", ".pt", ".pt2", ".pth", ".bin", ".pkl", ".sft", ".gguf"}

# Subset relevant to LLM downloads
LLM_EXTENSIONS = {".gguf", ".safetensors", ".bin"}
