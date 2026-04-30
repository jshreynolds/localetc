"""
Shared utilities for ai-manager download tools.

HuggingFace API interaction, sidecar metadata, error handling, logging.
"""

import json
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path


log = logging.getLogger(__name__)


def setup_logging(verbose=False):
    """Configure logging. WARNING by default, DEBUG on this package when verbose."""
    logging.basicConfig(
        level=logging.WARNING,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
    )
    if verbose:
        logging.getLogger("__main__").setLevel(logging.DEBUG)
        log.setLevel(logging.DEBUG)


def ensure_hf_hub():
    """Lazily import huggingface_hub, exit with helpful message if missing."""
    try:
        import huggingface_hub
        return huggingface_hub
    except ImportError:
        sys.exit("Install huggingface_hub first:  pip install huggingface_hub")


def fmt_size(size_bytes):
    """Format byte count as human-readable string."""
    if size_bytes is None:
        return "unknown"
    mb = size_bytes / (1024 * 1024)
    return f"{mb/1024:.1f} GB" if mb >= 1024 else f"{mb:.0f} MB"


def verify_remote(repo, filename, revision, extensions):
    """Check that repo + file exist on HF.

    Returns (commit_sha, file_size, gated).
    Exits with helpful message on failure.
    """
    from huggingface_hub import HfApi

    api = HfApi()

    info = api.model_info(repo_id=repo, revision=revision, files_metadata=True)
    commit_sha = info.sha
    gated = getattr(info, "gated", False)

    found = None
    for sibling in info.siblings or []:
        if sibling.rfilename == filename:
            found = sibling
            break

    if found is None:
        available = [s.rfilename for s in (info.siblings or [])
                     if any(s.rfilename.endswith(ext) for ext in extensions)]
        msg = f"File '{filename}' not found in {repo}."
        if available:
            msg += "\n\nAvailable model files:\n" + "\n".join(f"  {f}" for f in sorted(available))
        sys.exit(msg)

    return commit_sha, found.size, gated


def download_file(repo, filename, revision, dest_dir):
    """Download a file from HF directly into dest_dir. Returns the local path."""
    from huggingface_hub import hf_hub_download

    dest_dir.mkdir(parents=True, exist_ok=True)
    model_path = dest_dir / filename
    model_path.parent.mkdir(parents=True, exist_ok=True)

    log.debug(f"Downloading {filename} from {repo} -> {dest_dir}")
    try:
        hf_hub_download(
            repo,
            filename,
            revision=revision,
            local_dir=dest_dir,
        )
    except Exception as e:
        handle_hf_error(e, repo)

    if not model_path.exists():
        sys.exit(f"Download succeeded but file not found at expected path: {model_path}")

    return model_path


def handle_hf_error(e, repo_id):
    """Turn common HF errors into actionable messages."""
    err = str(e)
    if "401" in err or "Unauthorized" in err:
        sys.exit(
            f"Authentication required for {repo_id}.\n"
            f"This is likely a gated model. To fix:\n"
            f"  1. Accept the license at https://huggingface.co/{repo_id}\n"
            f"  2. Run: huggingface-cli login\n"
            f"     or set HF_TOKEN in your environment"
        )
    if "404" in err or "Not Found" in err:
        sys.exit(f"Repository not found: {repo_id}\nCheck the repo ID.")
    if "EntryNotFoundError" in type(e).__name__:
        sys.exit(f"File not found in repo {repo_id}.\nCheck the --file argument.")
    log.error(f"HF API error: {type(e).__name__}: {e}")
    sys.exit(1)


def build_source_block(repo, filename, revision, commit_sha):
    """Build the standard source metadata block for sidecars."""
    return {
        "platform": "huggingface",
        "repo_id": repo,
        "revision": revision,
        "commit_sha": commit_sha,
        "filename": filename,
        "url": f"https://huggingface.co/{repo}",
        "downloaded_at": datetime.now(timezone.utc).isoformat(),
    }


def sidecar_path(model_path):
    """Return the sidecar JSON path for a model file."""
    return model_path.with_suffix(model_path.suffix + ".json")


def write_sidecar(model_path, sidecar_data):
    """Write sidecar JSON next to a model file. Returns the sidecar path."""
    sp = sidecar_path(model_path)
    sp.write_text(json.dumps(sidecar_data, indent=2))
    return sp


def load_sidecar(model_path):
    """Load sidecar JSON for a model file. Returns dict or None."""
    sp = sidecar_path(model_path)
    if sp.exists():
        try:
            return json.loads(sp.read_text())
        except json.JSONDecodeError as e:
            log.warning(f"Corrupt sidecar {sp}: {e}")
            return None
    return None
