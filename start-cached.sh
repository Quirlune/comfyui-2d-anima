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

install_model() {
  local relative_path="$1"
  local destination="$2"
  mkdir -p "$(dirname "${destination}")"

  if [[ -n "${snapshot}" && -f "${snapshot}/${relative_path}" ]]; then
    ln -sfn "${snapshot}/${relative_path}" "${destination}"
    return
  fi

  : "${HF_TOKEN:?HF_TOKEN is required when the Runpod cached-model mount is unavailable}"
  echo "Cached mount unavailable; downloading ${relative_path} from ${HF_MODEL_ID}"
  wget --progress=dot:giga \
    --header="Authorization: Bearer ${HF_TOKEN}" \
    -O "${destination}.part" \
    "https://huggingface.co/${HF_MODEL_ID}/resolve/main/${relative_path}"
  mv "${destination}.part" "${destination}"
}

install_model "checkpoints/novaAnimeAM_v30.safetensors" "/comfyui/models/checkpoints/novaAnimeAM_v30.safetensors"
install_model "vae/qwen_image_vae.safetensors" "/comfyui/models/vae/qwen_image_vae.safetensors"
install_model "text_encoders/qwen_3_06b_base.safetensors" "/comfyui/models/text_encoders/qwen_3_06b_base.safetensors"
install_model "loras/anima-base-1-photo-background-v4.safetensors" "/comfyui/models/loras/anima-base-1-photo-background-v4.safetensors"
install_model "loras/rella_anima.safetensors" "/comfyui/models/loras/rella_anima.safetensors"

exec /worker-comfyui-start.sh
