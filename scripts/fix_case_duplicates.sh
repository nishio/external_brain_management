#!/bin/bash
#
# Fix duplicate files that differ only in case
# macOS filesystem is case-insensitive but Git is case-sensitive,
# which can cause duplicate files to exist in the Git index.
#
# This script:
# 1. Finds files that differ only in case
# 2. Checks their last commit date
# 3. Removes the older version from Git
# 4. Keeps the newer version

set -e

REPO_PATH="${1:-.}"
cd "$REPO_PATH"

echo "=== Checking for case-duplicate files in Git index ==="

# Get all files from Git index
git ls-files | sort > /tmp/git_files_sorted.txt

# Find duplicates (case-insensitive)
git ls-files | tr '[:upper:]' '[:lower:]' | sort | uniq -d > /tmp/duplicate_names_lower.txt

if [ ! -s /tmp/duplicate_names_lower.txt ]; then
    echo "No case-duplicate files found."
    exit 0
fi

echo "Found case-duplicate files. Analyzing..."

FILES_TO_REMOVE=()

while IFS= read -r lower_name; do
    # Find all variants of this filename
    variants=$(git ls-files | grep -i "^${lower_name}$" | sort)

    if [ $(echo "$variants" | wc -l) -le 1 ]; then
        continue
    fi

    echo ""
    echo "=== Duplicate variants for: $lower_name ==="

    # For each variant, get last commit date
    declare -A file_dates
    oldest_file=""
    oldest_date=""
    newest_file=""
    newest_date=""

    while IFS= read -r variant; do
        # Get last commit timestamp for this file
        commit_date=$(git log -1 --format="%at" -- "$variant" 2>/dev/null || echo "0")
        file_dates["$variant"]=$commit_date

        commit_date_human=$(git log -1 --format="%ai" -- "$variant" 2>/dev/null || echo "unknown")
        echo "  $variant: $commit_date_human"

        if [ -z "$oldest_date" ] || [ "$commit_date" -lt "$oldest_date" ]; then
            oldest_date=$commit_date
            oldest_file="$variant"
        fi

        if [ -z "$newest_date" ] || [ "$commit_date" -gt "$newest_date" ]; then
            newest_date=$commit_date
            newest_file="$variant"
        fi
    done <<< "$variants"

    # Remove all except the newest
    while IFS= read -r variant; do
        if [ "$variant" != "$newest_file" ]; then
            echo "  → Will remove (older): $variant"
            FILES_TO_REMOVE+=("$variant")
        else
            echo "  → Will keep (newer): $variant"
        fi
    done <<< "$variants"

done < /tmp/duplicate_names_lower.txt

if [ ${#FILES_TO_REMOVE[@]} -eq 0 ]; then
    echo ""
    echo "No files to remove."
    exit 0
fi

echo ""
echo "=== Summary ==="
echo "Files to remove from Git index: ${#FILES_TO_REMOVE[@]}"
echo ""

# Ask for confirmation
read -p "Proceed with removal? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Remove files from Git index
for file in "${FILES_TO_REMOVE[@]}"; do
    echo "Removing from Git: $file"
    git rm --cached "$file"
done

echo ""
echo "=== Done ==="
echo "Files removed from Git index. You can now commit the changes:"
echo "  git commit -m 'chore: remove duplicate files with case differences'"
echo "  git push origin main"

# Cleanup
rm -f /tmp/git_files_sorted.txt /tmp/duplicate_names_lower.txt
