#! /usr/bin/env bash

# formats we want to convert to
formats=(jxl webp avif png jpg)

# source file
source=$1

intermediate="$(b=${source##*/}; echo ${b%.*})"

echo "Source Image $source"

echo "Resizing image"
convert $source -resize 800x800 $intermediate-resized.tif

# Initialize an array to hold size information
declare -a sizeInfo

# Function to get file size with cross-platform support
get_file_size() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        stat -c %s "$1"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f %z "$1"
    else
        echo "Unsupported OS"
        exit 1
    fi
}

# Function to add size info for a given file
add_size_info() {
  local file_format=$1
  local filepath="$2"
  local file_size=$(get_file_size "$filepath")

  local size_kb=$(awk "BEGIN {printf \"%.2f\", $file_size/1024}")
  local size_mb=$(awk "BEGIN {printf \"%.2f\", $file_size/1048576}") # 1024 * 1024

  local size_display=""
  if [ $(echo "$file_size > 1048576" | bc) -eq 1 ]; then
    size_display="${size_mb}MB"
  elif [ $(echo "$file_size > 1024" | bc) -eq 1 ]; then
    size_display="${size_kb}KB"
  else
    size_display="${file_size}B"
  fi

  # Format: Format, Size in Bytes, Readable Size
  sizeInfo+=("$file_format $file_size $size_display")
}

# Add size info for the .tif file
add_size_info "tif" "$intermediate-resized.tif"

echo "Starting conversion of $intermediate-resized"

for format in ${formats[@]}
do
  echo "Converting to $format"
  convert $intermediate-resized.tif $intermediate.$format 
  # Correctly reference the converted file for size calculation
  add_size_info $format "$intermediate.$format"
done

# Display sizes after conversion in a table-like format
echo -e "\nSizes after conversion:"
printf "|%-8s | %-12s | %-10s|\n" "Format" "Size in Bytes" "Readable Size"
printf '|%-8s | %-12s | %-10s|\n' ":---:" ":---:" ":---:"
for size in "${sizeInfo[@]}"
do
  IFS=' ' read -r format size_bytes readable_size <<< "$size"
  printf "|%-8s | %-12s | %-10s|\n" $format "$size_bytes" "$readable_size"
done
