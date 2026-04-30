#!/usr/bin/env python3
"""
Create a new disposable ComfyUI pipeline.

Usage:
    setup_pipeline.py <pipeline-name> [python-version]
    setup_pipeline.py wan22-i2v 3.12

Requires:
    - AI_HOME env var set (models/ and pipelines/ are relative to it)
    - uv
    - git
"""

import argparse
import os
import shutil
import subprocess
import sys
import textwrap
from pathlib import Path

from generate_comfy_paths import generate_yaml
from config_comfy import COMFY_MODELS_ROOT


def check_env():
    """Validate that AI_HOME is set and required tools are on PATH."""
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
    """Run a command, printing it first. Exits on failure."""
    print(f"  → {' '.join(cmd)}")
    result = subprocess.run(cmd, **kwargs)
    if result.returncode != 0:
        sys.exit(f"Command failed (exit {result.returncode}): {' '.join(cmd)}")
    return result


def main():
    parser = argparse.ArgumentParser(description="Create a new disposable ComfyUI pipeline.")
    parser.add_argument("name", help="Pipeline name (e.g. wan22-i2v)")
    parser.add_argument("python_version", nargs="?", default="3.12", help="Python version (default: 3.12)")
    args = parser.parse_args()

    ai_home = check_env()
    pipelines_dir = ai_home / "pipelines"
    target = pipelines_dir / args.name

    if target.exists():
        sys.exit(f"Error: Pipeline '{args.name}' already exists at {target}")

    print(f"Creating pipeline: {args.name} (Python {args.python_version})")
    print(f"  Location: {target}")
    print(f"  Models:   {COMFY_MODELS_ROOT}")
    print()

    # ── Clone ComfyUI ────────────────────────────────────────

    pipelines_dir.mkdir(parents=True, exist_ok=True)
    run(["git", "clone", "https://github.com/comfyanonymous/ComfyUI.git", str(target)])

    # ── Create venv and install deps ─────────────────────────

    run(["uv", "venv", "--python", args.python_version], cwd=target)
    run(["uv", "pip", "install", "-r", "requirements.txt"], cwd=target)

    # ── Generate model paths config ──────────────────────────

    extra_model_paths = target / "extra_model_paths.yaml"
    extra_model_paths.write_text(generate_yaml(COMFY_MODELS_ROOT))
    print(f"  → Wrote {extra_model_paths}")

    # ── Create run script ────────────────────────────────────

    run_script = target / "run.sh"
    run_script.write_text(textwrap.dedent("""\
        #!/usr/bin/env bash
        set -euo pipefail
        cd "$(dirname "$0")"
        source .venv/bin/activate
        exec python main.py "$@"
    """))
    run_script.chmod(0o755)

    # ── Done ─────────────────────────────────────────────────

    print()
    print(f"Pipeline '{args.name}' ready.")
    print()
    print(f"  Run:          {target}/run.sh")
    print(f"  Run on port:  {target}/run.sh --port 8189")
    print(f"  Custom nodes: install_custom_node.py {args.name} <git-url>")
    print(f"  Nuke:         rm -rf {target}")


if __name__ == "__main__":
    main()