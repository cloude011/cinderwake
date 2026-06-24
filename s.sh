#!/bin/bash

# Script to organize HTML files into directories
# Creates a folder for each  file, moves the file into it, and renames it to index

# Check if there are any HTML files in the current directory
if ! ls * 1> /dev/null 2>&1; then
    echo "No HTML files found in the current directory."
    exit 1
fi

# Process each HTML file
for file in *; do
    # Skip if it's not a regular file
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    # Extract filename without extension
    basename="${file%}"
    
    # Skip if a directory with the same name already exists
    if [[ -d "$basename" ]]; then
        echo "Directory '$basename' already exists. Skipping '$file'."
        continue
    fi
    
    # Create directory
    mkdir "$basename"
    
    # Move file to directory and rename to index
    mv "$file" "$basename/index"
    
    echo "Processed: $file → $basename/index"
done

echo "HTML file organization complete!"
