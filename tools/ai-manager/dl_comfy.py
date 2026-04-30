#!/usr/bin/env python3
"""
Download a ComfyUI model from Hugging Face and create a sidecar metadata file.

Usage:
    python dl_comfy.py --repo Lykon/DreamShaper \
        --file DreamShaper_8_pruned.safetensors \
        --type checkpoint --base sd15

    python dl_comfy.py --dry-run --repo Lykon/DreamShaper \
        --file DreamShaper_8_pruned.safetensors \
        --type checkpoint --base sd15

    # Sidecar-only for an existing file:
    python dl_comfy.py --repo Lykon/DreamShaper \
        --file DreamShaper_8_pruned.safetensors \
        --type checkpoint --base sd15 \
        --existing ~/ai/models/comfy/checkpoints/sd15/DreamShaper_8_pruned.safetensors
"""

import argparse
import logging
import sys
from pathlib import Path

from config import MODEL_EXTENSIONS
from config_comfy import COMFY_MODELS_ROOT, MODEL_TYPE_FOLDERS, BASE_MODELS
from core import (
    setup_logging, ensure_hf_hub, verify_remote, download_file,
    handle_hf_error, fmt_size, build_source_block, write_sidecar,
)

log = logging.getLogger(__name__)


def resolve_dest(model_type, base):
    """Build destination directory under comfy models root."""
    dest = COMFY_MODELS_ROOT / MODEL_TYPE_FOLDERS[model_type]
    if base:
        dest = dest / base
    return dest


def main():
    p = argparse.ArgumentParser(description="Download a ComfyUI model from Hugging Face.")
    p.add_argument("--repo", required=True, help="HF repo (e.g. Lykon/DreamShaper)")
    p.add_argument("--file", required=True, help="Filename to download from the repo")
    p.add_argument("--type", required=True, choices=MODEL_TYPE_FOLDERS.keys(), help="Model type")
    p.add_argument("--base", choices=BASE_MODELS, default=None, help="Base architecture (optional)")
    p.add_argument("--revision", default="main", help="Git branch/revision (default: main)")
    p.add_argument("--version", default=None, help="Human version string (e.g. v2.1)")
    p.add_argument("--tags", default="", help="Comma-separated tags")
    p.add_argument("--notes", default="", help="Free-text notes")
    p.add_argument("--existing", type=Path, default=None, help="Skip download, create sidecar for this file")
    p.add_argument("--dry-run", action="store_true", help="Verify remote and show plan without downloading")
    p.add_argument("-v", "--verbose", action="store_true", help="Verbose logging")
    args = p.parse_args()

    setup_logging(args.verbose)
    ensure_hf_hub()

    dest_dir = resolve_dest(args.type, args.base)
    model_path = dest_dir / args.file if not args.existing else args.existing
    sidecar_file = model_path.with_suffix(model_path.suffix + ".json")

    # ── Verify remote ────────────────────────────────────────────
    commit_sha, file_size, gated = None, None, False
    if not args.existing:
        try:
            commit_sha, file_size, gated = verify_remote(
                args.repo, args.file, args.revision, MODEL_EXTENSIONS
            )
        except Exception as e:
            handle_hf_error(e, args.repo)

    # ── Dry run ──────────────────────────────────────────────────
    if args.dry_run:
        print(f"Repo:        {args.repo}")
        print(f"File:        {args.file}")
        print(f"Type:        {args.type} -> {MODEL_TYPE_FOLDERS[args.type]}/")
        print(f"Base:        {args.base or '(none)'}")
        print(f"Dest dir:    {dest_dir}")
        print(f"Model path:  {model_path}")
        print(f"Sidecar:     {sidecar_file}")
        if args.existing:
            exists = args.existing.exists()
            print(f"Existing:    {args.existing} ({'found' if exists else 'NOT FOUND'})")
            print(f"Action:      create sidecar only (no download)")
        else:
            print(f"Remote size: {fmt_size(file_size)}")
            print(f"Gated:       {'yes' if gated else 'no'}")
            print(f"Commit:      {commit_sha[:12]}")
            print(f"Action:      download from HF and create sidecar")
        print(f"\nDry run — nothing was downloaded or written.")
        return

    # ── Download or use existing ─────────────────────────────────
    if args.existing:
        if not args.existing.exists():
            sys.exit(f"File not found: {args.existing}")
        model_path = args.existing
        try:
            commit_sha, _, _ = verify_remote(
                args.repo, args.file, args.revision, MODEL_EXTENSIONS
            )
        except Exception:
            commit_sha = None
            log.warning("Could not fetch repo metadata for sidecar")
    else:
        model_path = download_file(args.repo, args.file, args.revision, dest_dir)

    # ── Write sidecar ────────────────────────────────────────────
    sidecar = {
        "source": build_source_block(args.repo, args.file, args.revision, commit_sha),
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

    sp = write_sidecar(model_path, sidecar)
    print(f"\nDownloaded: {args.repo} -> {model_path}")
    print(f"Sidecar:    {sp}")


if __name__ == "__main__":
    main()
