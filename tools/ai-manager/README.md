# ComfyUI Model Manager

Three files. One dependency.

## Setup

```bash
pip install huggingface_hub
```

Set `AI_MODELS_ROOT` to point to your models folder:

```bash
export AI_MODELS_ROOT="$HOME/ComfyUI/models"
```

Falls back to `~/ComfyUI/models` if unset.

## Files

- **config.py** — paths and model type/base mappings
- **dl_model.py** — download from HF + create sidecar metadata
- **registry.py** — build index, search, audit, stats

## Download a model

```bash
python dl_model.py \
    --repo Lykon/DreamShaper \
    --file dreamshaperXL_v21TurboDPMSDE.safetensors \
    --type checkpoint --base sdxl \
    --version "v2.1 Turbo" \
    --tags "general,photorealistic,turbo" \
    --notes "Good all-rounder. 4-8 steps with DPM++ SDE."
```

This downloads the file to `checkpoints/sdxl/` and writes a `.json` sidecar next to it.

To create a sidecar for a file you already downloaded manually:

```bash
python dl_model.py \
    --repo Lykon/DreamShaper \
    --file dreamshaperXL_v21.safetensors \
    --type checkpoint --base sdxl \
    --existing ~/ComfyUI/models/checkpoints/sdxl/dreamshaperXL_v21.safetensors
```

## Registry commands

```bash
python registry.py build                          # index all models
python registry.py search --type lora --base sdxl  # filter by type+base
python registry.py search --tag style              # filter by tag
python registry.py search --text "dreamshaperXL"          # free text search
python registry.py search --status untracked       # find models with no sidecar
python registry.py audit                           # orphans + disk usage
python registry.py audit --unused-days 90          # find stale models
python registry.py info checkpoints/sdxl/model.safetensors  # show sidecar
python registry.py status checkpoints/sdxl/old.safetensors archived  # change status
python registry.py stats                           # collection overview
```

## How it works

Every model file gets a sidecar JSON next to it (e.g. `model.safetensors.json`)
that records where it came from, what it's for, and whether you still need it.
ComfyUI ignores these files. The registry is just an aggregation of all sidecars
into one searchable index — the sidecars are the source of truth.

## Folder layout

```
ComfyUI/models/
├── checkpoints/
│   ├── sdxl/
│   │   ├── dreamshaperXL_v21.safetensors
│   │   └── dreamshaperXL_v21.safetensors.json   ← sidecar
│   └── flux/
├── loras/
│   ├── sdxl/
│   └── flux/
├── controlnet/
└── _registry/
    └── registry.json   ← master index (built by registry.py build)
```
