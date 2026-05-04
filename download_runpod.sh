#!/usr/bin/env bash

# write the Civit token
export CIVITAI_TOKEN="d5d6cd58d1ce50fc19d8b9f2da650b3a"

# this is a backup down model downloading for managing files the aria downloader doesn't like
mkdir /.civitai
echo "$CIVITAI_TOKEN" > /.civitai/config

download_model() {
    local url="$1"
    local full_path="$2"

    local destination_dir=$(dirname "$full_path")
    local destination_file=$(basename "$full_path")

    mkdir -p "$destination_dir"

    # Simple corruption check: file < 10MB or .aria2 files
    if [ -f "$full_path" ]; then
        local size_bytes=$(stat -f%z "$full_path" 2>/dev/null || stat -c%s "$full_path" 2>/dev/null || echo 0)
        local size_mb=$((size_bytes / 1024 / 1024))

        if [ "$size_bytes" -lt 10485760 ]; then  # Less than 10MB
            echo "🗑️  Deleting corrupted file (${size_mb}MB < 10MB): $full_path"
            rm -f "$full_path"
        else
            echo "✅ $destination_file already exists (${size_mb}MB), skipping download."
            return 0
        fi
    fi

    # Check for and remove .aria2 control files
    if [ -f "${full_path}.aria2" ]; then
        echo "🗑️  Deleting .aria2 control file: ${full_path}.aria2"
        rm -f "${full_path}.aria2"
        rm -f "$full_path"  # Also remove any partial file
    fi

    echo "📥 Downloading $destination_file to $destination_dir..."

    # Download without falloc (since it's not supported in your environment)
    aria2c -x 16 -s 16 -k 1M --continue=true -d "$destination_dir" -o "$destination_file" "$url" &

    echo "Download started in background for $destination_file"
}

LORA_IDS=(
)

export LORA_DIR="/ComfyUI/models/loras/"
export TEXT_ENC_DIR="/ComfyUI/models/text_encoders/"
export MODEL_DIR="/ComfyUI/models/diffusion_models/"   # <-- ADDED


#  Example Hugging Face

download_model "https://huggingface.co/SRodge00/blinkdoggy/resolve/main/iGoon%20-%20Blink_Front_Doggystyle_I2V_LOW.safetensors" "$LORA_DIR/iGoon - Blink_Front_Doggystyle_I2V_LOW.safetensors"

download_model "https://huggingface.co/SRodge00/blinkdoggy/resolve/main/iGoon%20-%20Blink_Front_Doggystyle_I2V_LOW.safetensors" "$LORA_DIR/iGoon - Blink_Front_Doggystyle_I2V_LOW.safetensors"

#  Examples CivitAI (will prompt for your key)

download_count=0

LORA_IDS=(
    "2376136" "2376143"  # XXX - SmoothMix Animations
    "2309690" "2309689" # SmoothMix Animations
)

for LORA_ID in "${LORA_IDS[@]}"; do
    sleep 1
    echo "🚀 Scheduling download: $LORA_ID to /ComfyUI/models/loras/"
    (cd "/ComfyUI/models/loras/" && download_with_aria.py -m "$LORA_ID") &
    ((download_count++))
done


# ------------------------------
# Diffusion Models (ADDED)
# ------------------------------
MODEL_IDS=(
    "2513182"
    "2513186"
)

for MODEL_ID in "${MODEL_IDS[@]}"; do
    sleep 1
    echo "🚀 Scheduling download: $MODEL_ID to /ComfyUI/models/diffusion_models/"
    (cd "/ComfyUI/models/diffusion_models/" && download_with_aria.py -m "$MODEL_ID") &
done


#  NSFW Text encoder
echo "Downloading NSFW text encoders..."
download_model "https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors" "$TEXT_ENC_DIR/nsfw_wan_umt5-xxl_fp8_scaled.safetensors"
download_model "https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_bf16.safetensors" "$TEXT_ENC_DIR/nsfw_wan_umt5-xxl_bf16.safetensors"


echo "✅ All LoRAs downloaded!"
echo ""

exit
