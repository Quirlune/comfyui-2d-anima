#!/usr/bin/env bash
set -euo pipefail

: "${HF_MODEL_ID:?Set HF_MODEL_ID to the cached Hugging Face repository, e.g. user/comfyui-2d-anima-models}"

cache_root="/runpod-volume/huggingface-cache/hub"
model_root="${cache_root}/models--${HF_MODEL_ID//\//--}"
snapshot=""

if [[ -f "${model_root}/refs/main" ]]; then
  revision="$(tr -d '\r\n' < "${model_root}/refs/main")"
  candidate="${model_root}/snapshots/${revision}"
  [[ -d "${candidate}" ]] && snapshot="${candidate}"
fi

if [[ -z "${snapshot}" && -d "${model_root}/snapshots" ]]; then
  snapshot="$(find "${model_root}/snapshots" -mindepth 1 -maxdepth 1 -type d | sort | head -n 1)"
fi

if [[ -z "${snapshot}" || ! -d "${snapshot}" ]]; then
  echo "Cached model snapshot not found for ${HF_MODEL_ID} under ${model_root}" >&2
  exit 1
fi

link_model() {
  local relative_path="$1"
  local destination="$2"
  local source="${snapshot}/${relative_path}"
  if [[ ! -f "${source}" ]]; then
    echo "Cached model file missing: ${source}" >&2
    exit 1
  fi
  mkdir -p "$(dirname "${destination}")"
  ln -sfn "${source}" "${destination}"
}

link_model "checkpoints/novaAnimeAM_v30.safetensors" "/comfyui/models/checkpoints/novaAnimeAM_v30.safetensors"
link_model "vae/qwen_image_vae.safetensors" "/comfyui/models/vae/qwen_image_vae.safetensors"
link_model "text_encoders/qwen_3_06b_base.safetensors" "/comfyui/models/text_encoders/qwen_3_06b_base.safetensors"
link_model "loras/anima-base-1-photo-background-v4.safetensors" "/comfyui/models/loras/anima-base-1-photo-background-v4.safetensors"
link_model "loras/rella_anima.safetensors" "/comfyui/models/loras/rella_anima.safetensors"

exec /worker-comfyui-start.sh
