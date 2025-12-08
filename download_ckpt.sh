#!/usr/bin/env bash
set -euo pipefail

# Uncomment to print every command for debugging, or run with DEBUG=1 ./download_ckpt.sh
[[ "${DEBUG:-0}" == "1" ]] && set -x

MODEL_REPO="Doubiiu/DynamiCrafter_512"
MODEL_FILE="model.ckpt"
TARGET_NAME="dynamicrafter-512.ckpt"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/custom/gaussians2life/guidance/dynamicrafter"
TARGET_DIR="$BASE_DIR/pretrained_models"

err_trap() {
  local exit_code=$?
  echo "❌ Error (code: $exit_code). See messages above." >&2
}
trap err_trap EXIT

require_cli() {
  echo "🔍 Checking for huggingface-cli..."
  if ! command -v huggingface-cli >/dev/null 2>&1; then
    echo "❌ huggingface-cli not found. Install via: pip install -U huggingface_hub" >&2
    exit 1
  fi
  echo "✅ huggingface-cli found."
}

main() {
  echo "📁 Script directory: $SCRIPT_DIR"
  echo "📂 Working in: $BASE_DIR"

  require_cli

  echo "📦 Ensuring target directory exists..."
  mkdir -p "$TARGET_DIR"

  echo "🚚 Entering target directory..."
  pushd "$TARGET_DIR" >/dev/null

  echo "⬇️  Downloading $MODEL_REPO :: $MODEL_FILE ..."
  huggingface-cli download "$MODEL_REPO" "$MODEL_FILE" --local-dir ./

  if [[ ! -f "$MODEL_FILE" ]]; then
    echo "❌ Download failed: $MODEL_FILE not found." >&2
    popd >/dev/null || true
    exit 1
  fi

  echo "📝 Renaming $MODEL_FILE -> $TARGET_NAME"
  mv -f "$MODEL_FILE" "$TARGET_NAME"

  echo "✅ Done! Saved at: $TARGET_DIR/$TARGET_NAME"

  echo "↩️  Returning to previous directory..."
  popd >/dev/null
  trap - EXIT
}

main "$@"