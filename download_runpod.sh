#!/usr/bin/env bash

# ------------------------------
# ComfyUI model downloader script
# ------------------------------

# CivitAI token
export CIVITAI_TOKEN="66ecb727815d644de90c1c2a25f2bb58"

# Directories (user-safe, in home folder)
export CIVITAI_CONFIG_DIR="$HOME/.civitai"
export LORA_DIR="$HOME/ComfyUI/models/loras"
export MODEL_DIR="$HOME/ComfyUI/models/diffusion_models"
export TEXT_ENC_DIR="$HOME/ComfyUI/models/text_encoders"

mkdir -p "$CIVITAI_CONFIG_DIR" "$LORA_DIR" "$MODEL_DIR" "$TEXT_ENC_DIR"
echo "$CIVITAI_TOKEN" > "$CIVITAI_CONFIG_DIR/config"

# ------------------------------
# Bash download function
# ------------------------------
download_model() {
    local url="$1"
    local full_path="$2"

    local dest_dir
    dest_dir=$(dirname "$full_path")
    local dest_file
    dest_file=$(basename "$full_path")

    mkdir -p "$dest_dir"

    # Check existing file
    if [ -f "$full_path" ]; then
        local size_bytes
        size_bytes=$(stat -c%s "$full_path" 2>/dev/null || echo 0)
        local size_mb=$((size_bytes / 1024 / 1024))

        if [ "$size_bytes" -lt 10485760 ]; then
            echo "🗑️  Deleting corrupted file (${size_mb}MB < 10MB): $full_path"
            rm -f "$full_path"
        else
            echo "✅ $dest_file already exists (${size_mb}MB), skipping download."
            return 0
        fi
    fi

    # Remove .aria2 partial files
    if [ -f "${full_path}.aria2" ]; then
        echo "🗑️  Removing partial file: ${full_path}.aria2"
        rm -f "${full_path}.aria2" "$full_path"
    fi

    echo "📥 Downloading $dest_file to $dest_dir..."
    aria2c -x 16 -s 16 -k 1M --continue=true -d "$dest_dir" -o "$dest_file" "$url" &
    echo "Download started in background for $dest_file"
}

# ------------------------------
# CivitAI Model IDs
# ------------------------------
MODEL_IDS=(2513182 2513186)

echo "🚀 Scheduling download of models to $MODEL_DIR..."
for ID in "${MODEL_IDS[@]}"; do
    sleep 1
    (cd "$MODEL_DIR" && download_with_aria.py -m "$ID") &
done

# ------------------------------
# CivitAI LoRA IDs
# ------------------------------
LORA_IDS=(2553271 2553151 1574869 1670972)

echo "🚀 Scheduling download of LoRAs to $LORA_DIR..."
for ID in "${LORA_IDS[@]}"; do
    sleep 1
    (cd "$LORA_DIR" && download_with_aria.py -m "$ID") &
done

# ------------------------------
# NSFW Text Encoders
# ------------------------------
echo "Downloading NSFW text encoders..."
download_model "https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors" "$TEXT_ENC_DIR/nsfw_wan_umt5-xxl_fp8_scaled.safetensors"
download_model "https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_bf16.safetensors" "$TEXT_ENC_DIR/nsfw_wan_umt5-xxl_bf16.safetensors"

echo "✅ All downloads scheduled!"