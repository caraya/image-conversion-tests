#! /usr/bin/env bash

# Formats we want to convert to
formats=(jxl webp avif png jpg)

# Source file
source=$1

# Extract the extension of the source file
extension="${source##*.}"

# Generate the base name for the intermediate file
intermediate="$(basename "$source" ".$extension")"

echo "Source Image: $source"

# Keep the intermediate file in the same format as the source
cp "$source" "$intermediate.$extension"

# Initialize an array to hold size information
declare -a sizeInfo

# Function to get file size with cross-platform support
get_file_size() {
    # Use awk to read file size directly from ls output to ensure compatibility
    # across different platforms and avoid invoking stat with different options
    ls -l "$1" | awk '{print $5}'
}

# Function to add size info for a given file
add_size_info() {
  local file_format=$1
  local filepath="$2"
  local file_size=$(get_file_size "$filepath")

  # Calculate size in KB and MB directly using awk for efficiency
  local size_display=$(awk -v size="$file_size" 'BEGIN {
    if (size > 1048576) {
      printf "%.2fMB", size / 1048576;
    } else if (size > 1024) {
      printf "%.2fKB", size / 1024;
    } else {
      printf "%dB", size;
    }
  }')

  # Format: Format, Size in Bytes, Readable Size
  sizeInfo+=("$file_format $file_size $size_display")
}

# Add size info for the original file
add_size_info "$extension" "$intermediate.$extension"

echo "Starting conversion of $intermediate"

for format in "${formats[@]}"
do
  echo "Converting to $format"
  # Convert the intermediate file to the desired format
  convert "$intermediate.$extension" "$intermediate.$format"
  # Add size information for the converted file
  add_size_info "$format" "$intermediate.$format"
done

# Display sizes after conversion in a table-like format
echo -e "\nSizes after conversion:"
printf "%-8s | %-12s | %-10s\n" "Format" "Size in Bytes" "Readable Size"
printf '%-8s | %-12s | %-10s\n' "--------" "------------" "------------"
for size in "${sizeInfo[@]}"
do
  IFS=' ' read -r format size_bytes readable_size <<< "$size"
  printf "%-8s | %-12s | %-10s\n" "$format" "$size_bytes" "$readable_size"
done
