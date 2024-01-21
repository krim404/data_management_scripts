#!/bin/bash
if [ $# -lt 2 ]; then
    echo "Usage: $0 <directory> <target>"
    exit 1
fi

# Array to hold files that need to be copied
files_to_copy=()

# Walk through the folders (in the same bash thread)
process_folder()
{
    SOURCE_DIR="$1"
    while IFS= read -r -d '' file; do
        process_file "$file" "$2" "$3"
    done < <(find "$SOURCE_DIR" -type f -print0)
}

# Process a single file
process_file()
{
    file="$1"
    TARGET_DIR="$2"
    BASE_DIR="$3"
        
    # Construct the target file path
    target_file="${TARGET_DIR}${file#$BASE_DIR}"
    # Check if the file exists in the target directory
    if [ ! -f "$target_file" ]; then
        # If it doesn't exist, add it to the list of files to copy
        files_to_copy+=("$file")
    fi
}

# Prepare the required params from the shell command
all_except_last=("${@:1:$#-1}")
last_argument="${!#}"

# Calculate the common path (must be done before processing the files)
common_path="${all_except_last[0]}"
for param in "${all_except_last[@]}"; do
    if [ -d "$param" ]; then
        while [[ "$param" != "$common_path"* ]]; do
            common_path="${common_path%/*}"
        done
    fi
done

# Check the parameters and execute the collection of differences
for param in "${all_except_last[@]}"; do
    if [ -d "$param" ]; then
        process_folder "$param" "$last_argument" "$common_path"
    elif [ -f "$param" ]; then
        process_file "$param" "$last_argument" "$common_path"
    fi
done

# Check if there are files to copy
if [ ${#files_to_copy[@]} -gt 0 ]; then
    
    # Fallback in case the common path is directly a file (only happens if only parameter is a direct file)
    if [ -f "$common_path" ]; then
        common_path="${common_path%/*}"
    fi
    
    # Use lfts_ordered_copy to do the work
    printf "%s\n" "${files_to_copy[@]}" | ltfs_ordered_copy -av -t "$TARGET_DIR" --keep-tree="$common_path"
fi
