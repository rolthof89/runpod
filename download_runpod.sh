#!/usr/bin/env bash

# write the CivitAI token
export CIVITAI_TOKEN="66ecb727815d644de90c1c2a25f2bb58"

# setup CivitAI config directory
mkdir -p /.civitai
echo "$CIVITAI_TOKEN" > /.civitai/config

# download function
download_model() {
    local url="$1"
    local full_path="$2"

    local destination_dir=$(dirname "$full_path")
    local destination_file=$(basename "$full_path")

    mkdir -p "$destination_dir"

    # Check for existing files
    if [ -f "$full_path" ]; then
        local size_bytes=$(stat -f%z "$full_path" 2>/dev/null || stat -c%s "$full_path" 2>/dev/null || echo 0)
        local size_mb=$((size_bytes / 1024 / 1024))

        if [ "$size_bytes" -lt 10485760 ]; then
            echo "🗑️  Deleting corrupted file (${size_mb}MB < 10MB): $full_path"
            rm -f "$full_path"
        else
            echo "✅ $destination_file already exists (${size_mb}MB), skipping download."
            return 0
        fi
    fi

    # Remove .aria2 control files
    if [ -f "${full_path}.aria2" ]; then
        echo "🗑️  Deleting .aria2 control file: ${full_path}.aria2"
        rm -f "${full_path}.aria2"
        rm -f "$full_path"
    fi

    echo "📥 Downloading $destination_file to $destination_dir..."
    aria2c -x 16 -s 16 -k 1M --continue=true -d "$destination_dir" -o "$destination_file" "$url" &
    echo "Download started in background for $destination_file"
}

# directories
export LORA_DIR="/ComfyUI/models/loras/"
export MODEL_DIR="/ComfyUI/models/diffusion_models/"
export TEXT_ENC_DIR="/ComfyUI/models/text_encoders/"

# CivitAI model IDs
MODEL_IDS=("2513182" "2513186")

echo "🚀 Scheduling download of models to /ComfyUI/models/diffusion_models/..."
for MODEL_ID in "${MODEL_IDS[@]}"; do
    sleep 1
    (cd "$MODEL_DIR" && download_with_aria.py -m "$MODEL_ID") &
done

# CivitAI LoRA IDs
LORA_IDS=("2553271" "2553151" "1574869" "1670972")

echo "🚀 Scheduling download of LoRAs to /ComfyUI/models/loras/..."
for LORA_ID in "${LORA_IDS[@]}"; do
    sleep 1
    (cd "$LORA_DIR" && download_with_aria.py -m "$LORA_ID") &
done

# NSFW Text encoders
echo "Downloading NSFW text encoders..."
download_model "https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors" "$TEXT_ENC_DIR/nsfw_wan_umt5-xxl_fp8_scaled.safetensors"
download_model "https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_bf16.safetensors" "$TEXT_ENC_DIR/nsfw_wan_umt5-xxl_bf16.safetensors"

echo "✅ All downloads scheduled!"
exit