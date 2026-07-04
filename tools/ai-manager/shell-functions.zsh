# Shell functions for the AI model manager (moved from env/enabled/89-ai-model-mgr).
# Sourced live from ~/.zshrc (see nix/home/shell.nix) — edits apply on next shell.
# The AI_HOME / AI_MODELS_ROOT / AI_MGR variables are set in nix/home/shell.nix.

_model_mgr_python() {
    if [ ! -d "$AI_MGR/.venv" ]; then
        echo "No .venv found in $AI_MGR"
        echo "Set it up with:"
        echo "  cd $AI_MGR"
        echo "  uv venv .venv"
        echo "  uv pip install huggingface_hub"
        return 1
    fi
    "$AI_MGR/.venv/bin/python" "$@"
}

dl_comfy() { _model_mgr_python "$AI_MGR/dl_comfy.py" "$@"; }
dl_llm()   { _model_mgr_python "$AI_MGR/dl_llm.py" "$@"; }
models()   { _model_mgr_python "$AI_MGR/registry.py" "$@"; }
generate_comfy_paths()  { _model_mgr_python "$AI_MGR/generate_comfy_paths.py" "$@"; }
setup_comfy_pipeline()  { _model_mgr_python "$AI_MGR/setup_comfy_pipeline.py" "$@"; }
install_comfy_custom_node()  { _model_mgr_python "$AI_MGR/install_custom_node.py" "$@"; }
