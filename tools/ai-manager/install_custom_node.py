#!/usr/bin/env python3
"""
Install a custom node into an existing ComfyUI pipeline.

Usage:
    install_custom_node.py <pipeline-name> <git-url> [--no-deps]
    install_custom_node.py wan22-i2v https://github.com/ltdrdata/ComfyUI-Manager.git
    install_custom_node.py wan22-i2v https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git --no-deps

Requires:
    - AI_HOME env var set (pipelines/ is relative to it)
    - uv
    - git
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


def check_env():
    ai_home = os.environ.get("AI_HOME")
    if not ai_home:
        sys.exit(
            "Error: AI_HOME is not set.\n"
            "Export it to the root of your AI workspace, e.g.:\n"
            "  export AI_HOME=$HOME/ai"
        )

    missing = [cmd for cmd in ("uv", "git") if not shutil.which(cmd)]
    if missing:
        sys.exit(f"Error: required commands not found on PATH: {', '.join(missing)}")

    return Path(ai_home)


def run(cmd: list[str], **kwargs):
    print(f"  → {' '.join(cmd)}")
    result = subprocess.run(cmd, **kwargs)
    if result.returncode != 0:
        sys.exit(f"Command failed (exit {result.returncode}): {' '.join(cmd)}")
    return result


def node_name_from_url(url: str) -> str:
    """Derive a directory name from a git URL (strip .git suffix)."""
    return url.rstrip("/").split("/")[-1].removesuffix(".git")


def main():
    parser = argparse.ArgumentParser(description="Install a custom node into a ComfyUI pipeline.")
    parser.add_argument("pipeline", help="Pipeline name (e.g. wan22-i2v)")
    parser.add_argument("url", help="Git URL of the custom node")
    parser.add_argument(
        "--no-deps",
        action="store_true",
        help="Skip installing requirements.txt even if one exists",
    )
    args = parser.parse_args()

    ai_home = check_env()
    pipeline_dir = ai_home / "pipelines" / args.pipeline

    if not pipeline_dir.exists():
        sys.exit(
            f"Error: pipeline '{args.pipeline}' not found at {pipeline_dir}\n"
            f"Create it first with: setup_comfy_pipeline.py {args.pipeline}"
        )

    venv = pipeline_dir / ".venv"
    if not venv.exists():
        sys.exit(f"Error: no .venv found in {pipeline_dir} — has the pipeline been set up?")

    custom_nodes_dir = pipeline_dir / "custom_nodes"
    custom_nodes_dir.mkdir(exist_ok=True)

    node_name = node_name_from_url(args.url)
    node_dir = custom_nodes_dir / node_name

    if node_dir.exists():
        sys.exit(f"Error: custom node '{node_name}' already exists at {node_dir}")

    print(f"Installing custom node: {node_name}")
    print(f"  Pipeline:  {pipeline_dir}")
    print(f"  Node dir:  {node_dir}")
    print()

    # ── Clone the custom node ─────────────────────────────────

    run(["git", "clone", args.url, str(node_dir)])

    # ── Install dependencies ──────────────────────────────────

    requirements = node_dir / "requirements.txt"

    if args.no_deps:
        print("  → Skipping dependency installation (--no-deps)")
    elif requirements.exists():
        print(f"  → Installing {requirements}")
        run(
            ["uv", "pip", "install", "-r", str(requirements)],
            cwd=pipeline_dir,
        )
    else:
        print("  → No requirements.txt found, skipping dependency installation")

    # ── Done ─────────────────────────────────────────────────

    print()
    print(f"Custom node '{node_name}' installed into pipeline '{args.pipeline}'.")


if __name__ == "__main__":
    main()
