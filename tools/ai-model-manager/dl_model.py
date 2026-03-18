#!/usr/bin/env python3
"""
Download a model from Hugging Face and create a sidecar metadata file.

Usage:
    python dl_model.py --repo Lykon/DreamShaper \
        --file dreamshaperXL_v21.safetensors \
        --type checkpoint --base sdxl \
        --tags "general,photorealistic" \
        --notes "Good all-rounder for SDXL"

    # Create sidecar for an already-downloaded file:
    python dl_model.py --repo Lykon/DreamShaper \
        --file dreamshaperXL_v21.safetensors \
        --type checkpoint --base sdxl \
        --existing ~/ComfyUI/models/checkpoints/sdxl/dreamshaperXL_v21.safetensors
"""

import argparse, json, logging, shutil, sys
from datetime import datetime, timezone
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

log.info("Loading config...")
from config import AI_MODELS_ROOT, MODEL_TYPE_FOLDERS, BASE_MODELS
log.info(f"AI_MODELS_ROOT = {AI_MODELS_ROOT}")

log.info("Importing huggingface_hub...")
try:
    from huggingface_hub import hf_hub_download, HfApi
    log.info("huggingface_hub loaded OK")
except ImportError:
    log.error("huggingface_hub not installed")
    sys.exit("Install huggingface_hub first:  pip install huggingface_hub")


def main():
    p = argparse.ArgumentParser(description="Download a HF model with metadata tracking.")
    p.add_argument("--repo", required=True, help="HF repo (e.g. Lykon/DreamShaper)")
    p.add_argument("--file", required=True, help="Filename to download from the repo")
    p.add_argument("--type", required=True, choices=MODEL_TYPE_FOLDERS.keys(), help="Model type")
    p.add_argument("--base", required=True, choices=BASE_MODELS, help="Base architecture")
    p.add_argument("--revision", default="main", help="Git branch/revision (default: main)")
    p.add_argument("--version", default=None, help="Human version string (e.g. v2.1)")
    p.add_argument("--tags", default="", help="Comma-separated tags")
    p.add_argument("--notes", default="", help="Free-text notes")
    p.add_argument("--existing", type=Path, default=None, help="Skip download, create sidecar for this file")
    args = p.parse_args()

    log.info(f"Repo: {args.repo}")
    log.info(f"File: {args.file}")
    log.info(f"Type: {args.type} -> folder: {MODEL_TYPE_FOLDERS[args.type]}")
    log.info(f"Base: {args.base}")

    # Resolve destination
    dest_dir = AI_MODELS_ROOT / MODEL_TYPE_FOLDERS[args.type] / args.base
    log.info(f"Destination dir: {dest_dir}")
    log.info(f"Creating destination dir (if needed)...")
    dest_dir.mkdir(parents=True, exist_ok=True)
    log.info(f"Destination dir OK")

    # Fetch commit SHA from HF
    commit_sha = None
    log.info(f"Fetching repo metadata from HF API for {args.repo} (revision={args.revision})...")
    try:
        api = HfApi()
        info = api.repo_info(repo_id=args.repo, revision=args.revision)
        commit_sha = info.sha
        log.info(f"Commit SHA: {commit_sha}")
    except Exception as e:
        log.warning(f"Could not fetch repo metadata: {type(e).__name__}: {e}")

    # Download or use existing
    if args.existing:
        log.info(f"Using existing file: {args.existing}")
        if not args.existing.exists():
            log.error(f"File not found: {args.existing}")
            sys.exit(1)
        model_path = args.existing
    else:
        model_path = dest_dir / args.file
        log.info(f"Creating destination dir (including any subdirs in filename)...")
        model_path.parent.mkdir(parents=True, exist_ok=True)
        log.info(f"Starting download: {args.file} from {args.repo}...")
        try:
            cached = Path(hf_hub_download(
                args.repo, args.file, revision=args.revision
            ))
            log.info(f"Downloaded to HF cache: {cached}")
        except Exception as e:
            log.error(f"Download failed: {type(e).__name__}: {e}")
            sys.exit(1)

        log.info(f"Copying from cache to {model_path}...")
        try:
            shutil.copy2(cached, model_path)
            size = model_path.stat().st_size / (1024 * 1024)
            log.info(f"Copy complete ({size:.0f} MB)")
        except Exception as e:
            log.error(f"Copy failed: {type(e).__name__}: {e}")
            sys.exit(1)

    # Write sidecar
    log.info("Building sidecar metadata...")
    sidecar = {
        "source": {
            "platform": "huggingface",
            "repo_id": args.repo,
            "revision": args.revision,
            "commit_sha": commit_sha,
            "filename": args.file,
            "url": f"https://huggingface.co/{args.repo}",
            "downloaded_at": datetime.now(timezone.utc).isoformat(),
        },
        "model": {
            "name": args.repo.split("/")[-1],
            "version": args.version,
            "type": args.type,
            "base_model": args.base,
            "tags": [t.strip() for t in args.tags.split(",") if t.strip()],
        },
        "local": {
            "status": "active",
            "notes": args.notes,
            "last_used": None,
            "keep": True,
        },
    }

    sidecar_path = model_path.with_suffix(model_path.suffix + ".json")
    log.info(f"Writing sidecar to {sidecar_path}...")
    try:
        sidecar_path.write_text(json.dumps(sidecar, indent=2))
        log.info("Sidecar written OK")
    except Exception as e:
        log.error(f"Failed to write sidecar: {type(e).__name__}: {e}")
        sys.exit(1)

    print(f"\nDownloaded: {args.repo} -> {model_path}")
    print(f"Sidecar:    {sidecar_path}")


if __name__ == "__main__":
    main()
