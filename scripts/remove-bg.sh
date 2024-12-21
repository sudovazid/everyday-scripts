#!/bin/bash

# Save this as rembg-helper.sh
# Make it executable with: chmod +x rembg-helper.sh

CONTAINER_ID="c2c96241b3ae"
INPUT_DIR="$HOME/rembg/input"
OUTPUT_DIR="$HOME/rembg/output"

# Create directories if they don't exist
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

# Function to remove background from a single image
remove_bg_single() {
    local input_file="$1"
    local filename=$(basename "$input_file")
    local output_file="$OUTPUT_DIR/${filename%.*}.png"
    
    echo "Processing: $filename"
    docker run -v "$INPUT_DIR:/app/input" -v "$OUTPUT_DIR:/app/output" \
        $CONTAINER_ID python /app/rembg.py i "/app/input/$filename" "/app/output/${filename%.*}.png"
    echo "Saved to: $output_file"
}

# Function to process entire directory
process_directory() {
    echo "Processing all images in $INPUT_DIR"
    docker run -v "$INPUT_DIR:/app/input" -v "$OUTPUT_DIR:/app/output" \
        $CONTAINER_ID rembg p /app/input /app/output
    echo "All images processed. Check $OUTPUT_DIR for results"
}

# Main script
case "$1" in
    "single")
        if [ -z "$2" ]; then
            echo "Usage: $0 single <image_file>"
            exit 1
        fi
        remove_bg_single "$2"
        ;;
    "batch")
        process_directory
        ;;
    *)
        echo "Usage:"
        echo "  $0 single <image_file> - Process a single image"
        echo "  $0 batch               - Process all images in input directory"
        ;;
esac