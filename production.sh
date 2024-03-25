#!/usr/bin/env bash

# Adjusted target formats for conversion
formats=(jxl webp avif png jpg)

# Directory containing source images
source_dir=$1

# Target directory for converted images. If not provided, use 'converted' in the current directory.
target_dir=${2:-$(pwd)/converted}

# Function to check and get file size with cross-platform support
get_file_size() {
    local file_path="$1"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        stat --printf="%s" "$file_path"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f %z "$file_path"
    else
        echo "Unsupported OS"
        exit 1
    fi
}

# Function to format size with 2 decimal precision using awk
# Displays KB if > 1023 bytes and MB if > 1023 KB
format_size() {
  local size=$1
  if [ $size -gt 1048575 ]; then
    echo $(awk -v s="$size" 'BEGIN { printf "%.2f MB", s/1048576; }')
  elif [ $size -gt 1023 ]; then
    echo $(awk -v s="$size" 'BEGIN { printf "%.2f KB", s/1024; }')
  else
    echo "${size} B"
  fi
}

# Validate and prepare directories
if [ ! -d "$source_dir" ]; then
  echo "Error: Source directory does not exist."
  exit 1
fi

if [ -z "$(ls -A $source_dir)" ]; then
  echo "Error: Source directory is empty."
  exit 1
fi

if [ ! -d "$target_dir" ]; then
  echo "Target directory does not exist, creating it at $target_dir"
  mkdir -p "$target_dir"
fi

# Process each image in the directory
for source in $source_dir/*; do
  # Skip if not an image
  if ! [[ $source =~ \.(jpg|jpeg|png|tiff|tif|bmp)$ ]]; then
    continue
  fi

  base_name=$(basename "$source")
  intermediate="${base_name%.*}"

  echo -e "\nProcessing image $source"

  # Header for the table
  echo -e "Format\tSize in Bytes\tFormatted Size"
  echo -e "------\t-------------\t----------------"

  # Convert and calculate file sizes for each format
  for format in "${formats[@]}"; do
    output="$target_dir/${intermediate}.${format}"
    # Conversion might fail for formats not supported by your ImageMagick version
    if convert "$source" "$output"; then
      size_bytes=$(get_file_size "$output")
      size_formatted=$(format_size $size_bytes)
      echo -e "${format}\t${size_bytes}\t${size_formatted}"
    else
      echo -e "${format}\tConversion Failed\t-"
    fi
  done
done
