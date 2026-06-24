#!/bin/bash

# GitBook Static Asset Downloader
# This script downloads static assets from GitBook and updates references in HTML files

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INDEX_FILE="index.html"
STATIC_DIR="static"
GITBOOK_DOMAIN="https://static-2c.gitbook.com"
PREFIX="emberlore-whitepaper"

echo -e "${BLUE}GitBook Static Asset Downloader${NC}"
echo "=================================="

# Check if index.html exists
if [ ! -f "$INDEX_FILE" ]; then
    echo -e "${RED}Error: $INDEX_FILE not found in current directory${NC}"
    exit 1
fi

# Create static directory if it doesn't exist
if [ ! -d "$STATIC_DIR" ]; then
    echo -e "${YELLOW}Creating $STATIC_DIR directory...${NC}"
    mkdir -p "$STATIC_DIR"
fi

# Function to extract URLs from HTML
extract_urls() {
    local file="$1"
    # Extract URLs from href and src attributes that start with the GitBook domain
    grep -oE "(href|src)=[\"'][^\"']*${GITBOOK_DOMAIN}[^\"']*[\"']" "$file" | \
    grep -oE "${GITBOOK_DOMAIN}[^\"']*" | \
    sort -u
}

# Function to download a file
download_file() {
    local url="$1"
    local relative_path="${url#$GITBOOK_DOMAIN}"
    
    # Remove leading slash if present
    relative_path="${relative_path#/}"
    
    # Create the full local path
    local local_path="$STATIC_DIR/$relative_path"
    local local_dir=$(dirname "$local_path")
    
    # Create directory structure if it doesn't exist
    if [ ! -d "$local_dir" ]; then
        mkdir -p "$local_dir"
    fi
    
    # Download the file
    echo -e "${BLUE}Downloading:${NC} $url"
    echo -e "${BLUE}    -> ${NC}$local_path"
    
    if curl -sL --fail "$url" -o "$local_path"; then
        echo -e "${GREEN}    ✓ Downloaded successfully${NC}"
        return 0
    else
        echo -e "${RED}    ✗ Failed to download${NC}"
        return 1
    fi
}

# Function to update references in HTML files
update_references() {
    local file="$1"
    local temp_file=$(mktemp)
    
    echo -e "${BLUE}Updating references in:${NC} $file"
    
    # Use sed to replace all GitBook URLs with local paths
    sed -E "s|${GITBOOK_DOMAIN}/_next/static/|${PREFIX}/static/|g" "$file" > "$temp_file"
    
    # Check if any changes were made
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        echo -e "${GREEN}    ✓ Updated references${NC}"
    else
        rm "$temp_file"
        echo -e "${YELLOW}    - No changes needed${NC}"
    fi
}

# Main execution
echo -e "${YELLOW}Step 1: Extracting URLs from $INDEX_FILE...${NC}"
urls=$(extract_urls "$INDEX_FILE")

if [ -z "$urls" ]; then
    echo -e "${RED}No GitBook URLs found in $INDEX_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Found $(echo "$urls" | wc -l) URLs to download${NC}"
echo

# Download each URL
echo -e "${YELLOW}Step 2: Downloading assets...${NC}"
downloaded_count=0
failed_count=0

while IFS= read -r url; do
    if download_file "$url"; then
        ((downloaded_count++))
    else
        ((failed_count++))
    fi
    echo
done <<< "$urls"

echo -e "${GREEN}Downloaded: $downloaded_count files${NC}"
if [ $failed_count -gt 0 ]; then
    echo -e "${RED}Failed: $failed_count files${NC}"
fi
echo

# Update references in all HTML files
echo -e "${YELLOW}Step 3: Updating references in HTML files...${NC}"

# Find all HTML files recursively
html_files=$(find . -name "*.html" -type f)

if [ -z "$html_files" ]; then
    echo -e "${RED}No HTML files found in the current directory${NC}"
    exit 1
fi

html_count=$(echo "$html_files" | wc -l)
echo -e "${GREEN}Found $html_count HTML files to update${NC}"
echo

# Update each HTML file
while IFS= read -r file; do
    update_references "$file"
done <<< "$html_files"

echo
echo -e "${GREEN}✓ Process completed successfully!${NC}"
echo -e "${BLUE}Summary:${NC}"
echo -e "  • Downloaded $downloaded_count assets to $STATIC_DIR/"
echo -e "  • Updated references in $html_count HTML files"
echo -e "  • Assets are now referenced with prefix: $PREFIX/static/"

if [ $failed_count -gt 0 ]; then
    echo -e "${YELLOW}Note: $failed_count files failed to download. Check the output above for details.${NC}"
fi