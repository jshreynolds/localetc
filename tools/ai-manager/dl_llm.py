#!/usr/bin/env python3
"""
Download an LLM model from Hugging Face and create a sidecar metadata file.

Usage:
    python dl_llm.py --repo TheBloke/Llama-2-7B-GGUF \
        --file llama-2-7b.Q4_K_M.gguf

    python dl_llm.py --dry-run --repo bartowski/Qwen3-30B-A3B-GGUF \
        --file Qwen3-30B-A3B-Q4_K_M.gguf
"""

import argparse
import logging
import re
import sys
from pathlib import Path

from config import AI_MODELS_ROOT, LLM_EXTENSIONS
from core import (
    setup_logging, ensure_hf_hub, verify_remote, download_file,
    handle_hf_error, fmt_size, build_source_block, write_sidecar,
)

log = logging.getLogger(__name__)

LLM_MODELS_ROOT = AI_MODELS_ROOT / "llm"


def detect_format(filename):
    """Detect model format from file extension."""
    for ext in (".gguf", ".safetensors", ".bin", ".pt", ".ckpt"):
        if filename.endswith(ext):
            return ext.lstrip(".")
    return None


def detect_quantization(filename):
    """Extract quantization level from filename (e.g. Q4_K_M, Q8_0, IQ3_XS)."""
    match = re.search(r'[.-]((?:I?Q\d+_[A-Z0-9_]+)|(?:I?Q\d+))[.-]', f".{filename}.")
    return match.group(1) if match else None


def resolve_dest(repo):
    """Build destination directory under LLM models root, mirroring HF repo structure."""
    org, name = repo.split("/", 1)
    return LLM_MODELS_ROOT / org / name


def main():
    p = argparse.ArgumentParser(description="Download an LLM model from Hugging Face.")
    p.add_argument("--repo", required=True, help="HF repo (e.g. TheBloke/Llama-2-7B-GGUF)")
    p.add_argument("--file", required=True, help="Filename to download from the repo")
    p.add_argument("--revision", default="main", help="Git branch/revision (default: main)")
    p.add_argument("--tags", default="", help="Comma-separated tags (e.g. coding,reasoning)")
    p.add_argument("--notes", default="", help="Free-text notes")
    p.add_argument("--existing", type=Path, default=None, help="Skip download, create sidecar for this file")
    p.add_argument("--dry-run", action="store_true", help="Verify remote and show plan without downloading")
    p.add_argument("-v", "--verbose", action="store_true", help="Verbose logging")
    args = p.parse_args()

    setup_logging(args.verbose)
    ensure_hf_hub()

    dest_dir = resolve_dest(args.repo)
    model_path = dest_dir / args.file if not args.existing else args.existing
    sidecar_file = model_path.with_suffix(model_path.suffix + ".json")

    fmt = detect_format(args.file)
    quant = detect_quantization(args.file)

    # ── Verify remote ────────────────────────────────────────────
    commit_sha, file_size, gated = None, None, False
    if not args.existing:
        try:
            commit_sha, file_size, gated = verify_remote(
                args.repo, args.file, args.revision, LLM_EXTENSIONS
            )
        except Exception as e:
            handle_hf_error(e, args.repo)

    # ── Dry run ──────────────────────────────────────────────────
    if args.dry_run:
        print(f"Repo:        {args.repo}")
        print(f"File:        {args.file}")
        print(f"Format:      {fmt or '(unknown)'}")
        print(f"Quant:       {quant or '(none)'}")
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
                args.repo, args.file, args.revision, LLM_EXTENSIONS
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
            "format": fmt,
            "quantization": quant,
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
