#!/bin/bash

# scripts/common/gather_context.sh
# Gathers file contents into a deterministic context bundle for prompt/task input.
#
# Usage: ./gather_context.sh <path1> <path2> ... > context.txt

set -euo pipefail

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

printed_files=0
missing_items=0

sha256_file() {
    local file_path=$1
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file_path" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file_path" | awk '{print $1}'
    else
        echo "unavailable"
    fi
}

print_manifest_header() {
    echo "CONTEXT_BUNDLE_VERSION: 1"
    echo "GENERATED_AT_UTC: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "REQUESTED_INPUTS: $#"
    echo "FORMAT: FILE sections with metadata + content"
    echo
}

print_file_content() {
    local file_path=$1
    local file_size
    local file_hash
    file_size=$(wc -c < "$file_path" | tr -d ' ')
    file_hash=$(sha256_file "$file_path")

    echo "================================================================================"
    echo "FILE: $file_path"
    echo "SIZE_BYTES: $file_size"
    echo "SHA256: $file_hash"
    echo "================================================================================"
    cat "$file_path"
    echo
    echo

    printed_files=$((printed_files + 1))
}

print_manifest_header "$@"

for item in "$@"; do
    if [ -f "$item" ]; then
        print_file_content "$item"
    elif [ -d "$item" ]; then
        info "Scanning directory: $item"
        # Deterministic traversal: filter noisy paths, then sort.
        while IFS= read -r file; do
            print_file_content "$file"
        done < <(
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
            \) | LC_ALL=C sort
        )
    else
        warn "Path not found or not accessible: $item"
        missing_items=$((missing_items + 1))
    fi
done

echo "CONTEXT_BUNDLE_SUMMARY:"
echo "- FILE_COUNT: $printed_files"
echo "- MISSING_INPUTS: $missing_items"
