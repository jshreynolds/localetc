# AI Model Manager

Two download tools with a shared registry. One dependency.

## Setup

```bash
pip install huggingface_hub
```

Models default to `~/ai/models/` with two subdirectories:

```
~/ai/models/
├── comfy/          ← ComfyUI models (checkpoints, LoRAs, controlnets, etc.)
├── llm/            ← LLM models (GGUF, safetensors)
└── _registry/
    └── registry.json
```

Override with `AI_MODELS_ROOT` env var.

## Download a ComfyUI model

```bash
python dl_comfy.py \
    --repo Lykon/DreamShaper \
    --file DreamShaper_8_pruned.safetensors \
    --type checkpoint --base sd15 \
    --tags "general,photorealistic" \
    --notes "Good all-rounder. 4-8 steps with DPM++ SDE."
```

`--base` is optional. `--dry-run` verifies the remote and shows the plan without downloading.

## Download an LLM model

```bash
python dl_llm.py \
    --repo TheBloke/Llama-2-7B-GGUF \
    --file llama-2-7b.Q4_K_M.gguf \
    --family llama2 \
    --tags "coding,general"
```

`--family` is optional (creates a subfolder when set). Format and quantization are auto-detected from the filename.

## Dry run

Both tools support `--dry-run` to verify the model exists on HF and show where it would be downloaded:

```bash
python dl_comfy.py --dry-run --repo Lykon/DreamShaper --file DreamShaper_8_pruned.safetensors --type checkpoint
python dl_llm.py --dry-run --repo TheBloke/Llama-2-7B-GGUF --file llama-2-7b.Q4_K_M.gguf
```

## Create a sidecar for an existing file

```bash
python dl_comfy.py --repo Lykon/DreamShaper --file DreamShaper_8_pruned.safetensors \
    --type checkpoint --base sd15 \
    --existing ~/ai/models/comfy/checkpoints/sd15/DreamShaper_8_pruned.safetensors
```

## Registry commands

```bash
python registry.py build                              # index all models
python registry.py search --domain comfy --type lora   # ComfyUI LoRAs
python registry.py search --domain llm --family qwen3  # LLMs by family
python registry.py search --tag style                  # filter by tag
python registry.py search --text "dreamshaperXL"       # free text search
python registry.py audit                               # orphans + disk usage
python registry.py audit --unused-days 90              # find stale models
python registry.py info comfy/checkpoints/sdxl/m.safetensors  # show sidecar
python registry.py stats                               # collection overview
```

## Files

- **core.py** — shared HF API, sidecar I/O, error handling
- **config.py** — shared config (AI_MODELS_ROOT, extensions)
- **config_comfy.py** — ComfyUI-specific config (type folders, base models)
- **dl_comfy.py** — download ComfyUI models
- **dl_llm.py** — download LLM models
- **registry.py** — build index, search, audit, stats
- **generate_comfy_paths.py** — generate extra_model_paths.yaml for ComfyUI
- **setup_comfy_pipeline.py** — create a disposable ComfyUI pipeline
- **install_custom_node.py** — install custom nodes into a pipeline

## How it works

Every model file gets a sidecar JSON next to it (e.g. `model.safetensors.json`)
that records where it came from, what it's for, and whether you still need it.
ComfyUI ignores these files. The registry is an aggregation of all sidecars
into one searchable index — the sidecars are the source of truth.

## Folder layout

```
~/ai/models/
├── comfy/
│   ├── checkpoints/
│   │   ├── sdxl/
│   │   │   ├── dreamshaperXL.safetensors
│   │   │   └── dreamshaperXL.safetensors.json   ← sidecar
│   │   └── flux/
│   ├── loras/
│   ├── controlnet/
│   └── gguf/
├── llm/
│   ├── llama2/
│   │   ├── llama-2-7b.Q4_K_M.gguf
│   │   └── llama-2-7b.Q4_K_M.gguf.json         ← sidecar
│   └── qwen3/
└── _registry/
    └── registry.json
```
