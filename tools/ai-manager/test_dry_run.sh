#!/usr/bin/env bash
# Test dry-run across a representative sample of model types.
# Every case hits the HF API to verify the model exists.
#
# Usage:
#   ./test_dry_run.sh           # run all tests
#   ./test_dry_run.sh -v        # verbose (pass -v to download tools)

set -euo pipefail
cd "$(dirname "$0")"

VERBOSE="${1:-}"
PASS=0
FAIL=0
ERRORS=()

run_test() {
    local label="$1"
    local script="$2"
    shift 2
    printf "%-60s " "$label"
    if output=$(python "$script" --dry-run $VERBOSE "$@" 2>&1); then
        echo "PASS"
        PASS=$((PASS + 1))
    else
        echo "FAIL"
        ERRORS+=("$label: $output")
        FAIL=$((FAIL + 1))
    fi
}

run_test_expect_fail() {
    local label="$1"
    local script="$2"
    shift 2
    printf "%-60s " "$label"
    if output=$(python "$script" --dry-run $VERBOSE "$@" 2>&1); then
        echo "FAIL (expected failure but got success)"
        ERRORS+=("$label: expected failure")
        FAIL=$((FAIL + 1))
    else
        echo "PASS (expected failure)"
        PASS=$((PASS + 1))
    fi
}

COMFY="dl_comfy.py"
LLM="dl_llm.py"

echo "=== ai-manager dry-run tests ==="
echo ""
echo "--- ComfyUI models (dl_comfy.py) ---"
echo ""

# ── Checkpoints with --base ─────────────────────────────────────
run_test "comfy: checkpoint + sdxl base" $COMFY \
    --repo Lykon/DreamShaper --file DreamShaperXL_Turbo_dpmppSdeKarras_half_pruned_6.safetensors \
    --type checkpoint --base sdxl

run_test "comfy: checkpoint + sd15 base" $COMFY \
    --repo Lykon/DreamShaper --file DreamShaper_8_pruned.safetensors \
    --type checkpoint --base sd15

# ── LoRA with --base ────────────────────────────────────────────
run_test "comfy: lora + sdxl base" $COMFY \
    --repo latent-consistency/lcm-lora-sdxl --file pytorch_lora_weights.safetensors \
    --type lora --base sdxl

# ── Diffusion models with base ──────────────────────────────────
run_test "comfy: diffusion_models + flux base" $COMFY \
    --repo black-forest-labs/FLUX.1-schnell --file flux1-schnell.safetensors \
    --type diffusion_models --base flux

# ── VAE — no base ──────────────────────────────────────────────
run_test "comfy: vae, no base" $COMFY \
    --repo stabilityai/sd-vae-ft-mse --file diffusion_pytorch_model.safetensors \
    --type vae

# ── Upscaler — no base ─────────────────────────────────────────
run_test "comfy: upscaler, no base" $COMFY \
    --repo Phips/4xNomosUniDAT_bokeh_jpg --file 4xNomosUniDAT_bokeh_jpg.safetensors \
    --type upscaler

# ── Embedding — no base ────────────────────────────────────────
run_test "comfy: embedding, no base" $COMFY \
    --repo sd-concepts-library/cat-toy --file learned_embeds.bin \
    --type embedding

# ── CLIP — no base ──────────────────────────────────────────────
run_test "comfy: clip, no base" $COMFY \
    --repo openai/clip-vit-large-patch14 --file model.safetensors \
    --type clip

# ── ControlNet with base ────────────────────────────────────────
run_test "comfy: controlnet + sdxl base" $COMFY \
    --repo diffusers/controlnet-canny-sdxl-1.0 --file diffusion_pytorch_model.fp16.safetensors \
    --type controlnet --base sdxl

# ── ComfyUI GGUF (quantized diffusion model) ───────────────────
run_test "comfy: gguf + flux base" $COMFY \
    --repo city96/FLUX.1-dev-gguf --file flux1-dev-Q4_K_S.gguf \
    --type gguf --base flux

# ── ComfyUI error cases ────────────────────────────────────────
run_test_expect_fail "comfy: bad repo (should fail)" $COMFY \
    --repo totally/fake-repo-that-does-not-exist --file nope.safetensors \
    --type checkpoint

run_test_expect_fail "comfy: bad filename (should fail)" $COMFY \
    --repo Lykon/DreamShaper --file this_file_does_not_exist.safetensors \
    --type checkpoint

echo ""
echo "--- LLM models (dl_llm.py) ---"
echo ""

# ── GGUF — no family (flat) ────────────────────────────────────
run_test "llm: gguf, no family (flat)" $LLM \
    --repo TheBloke/Llama-2-7B-GGUF --file llama-2-7b.Q4_K_M.gguf

# ── GGUF — with family ─────────────────────────────────────────
run_test "llm: gguf + llama2 family" $LLM \
    --repo TheBloke/Llama-2-7B-GGUF --file llama-2-7b.Q4_K_M.gguf \
    --family llama2

# ── GGUF — different quant ──────────────────────────────────────
run_test "llm: gguf Q8_0 quant detection" $LLM \
    --repo TheBloke/Llama-2-7B-GGUF --file llama-2-7b.Q8_0.gguf \
    --family llama2

# ── LLM error cases ────────────────────────────────────────────
run_test_expect_fail "llm: bad repo (should fail)" $LLM \
    --repo totally/fake-repo-that-does-not-exist --file nope.gguf

run_test_expect_fail "llm: bad filename (should fail)" $LLM \
    --repo TheBloke/Llama-2-7B-GGUF --file this_file_does_not_exist.gguf

# ── Summary ─────────────────────────────────────────────────────
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo ""
    echo "Failures:"
    for err in "${ERRORS[@]}"; do
        echo "  - $err"
    done
    exit 1
fi
