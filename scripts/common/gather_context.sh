#!/bin/bash

# scripts/common/gather_context.sh
# Gathers contents of files and directories for context
# 
# Usage: ./gather_context.sh <path1> <path2> ... > context.txt

# --- UI Helpers ---
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file_or_dir1> [file_or_dir2] ..." >&2
    exit 1
fi

print_file_content() {
    local file_path=$1
    echo "================================================================================"
    echo "FILE: $file_path"
    echo "================================================================================"
    cat "$file_path"
    echo -e "\n"
}

for item in "$@"; do
    if [ -f "$item" ]; then
        print_file_content "$item"
    elif [ -d "$item" ]; then
        info "Scanning directory: $item"
        # Find all files, excluding .git, node_modules, and other common binary/noise dirs
        find "$item" -type f \( \
            -not -path "*/.*" \
            -not -path "*/node_modules/*" \
            -not -path "*/dist/*" \
            -not -path "*/build/*" \
            -not -path "*/.git/*" \
            -not -name "*.png" \
            -not -name "*.jpg" \
            -not -name "*.jpeg" \
            -not -name "*.gif" \
            -not -name "*.ico" \
            -not -name "*.pdf" \
            -not -name "*.zip" \
            -not -name "package-lock.json" \
            -not -name "yarn.lock" \
        \) | while read -r file; do
            print_file_content "$file"
        done
    else
        warn "Path not found or not accessible: $item"
    fi
done
