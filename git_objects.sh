#!/bin/bash

echo "Unpacking Object Packs"

for file in $(find .git/objects -type f -name "*.pack"); do
    filename=$(basename "$file")
    echo "git unpack-objects -r $filename"
    git unpack-objects -r "$filename"
done

echo "Done"
mkdir -p objects
echo "Extracting content for each Object"

for file in $(find .git/objects -type f ! -name "pack" ! -name "info" ! -name "*.idx" ! -name "*.pack"); do
    dir=$(dirname "$file" | tail -c 3)
    filename=$(basename "$file")

    # Prepend directory name to hash
    hash=$dir$filename

    # If the file is compressed it will find the '' character
    if git cat-file -p "$hash" | grep -q ''; then
        echo "git cat-file -p $hash | zstd -d > objects/$hash-decoded.txt"
    	  git cat-file -p "$hash" | zstd -d > objects/"$hash"-decoded.txt

    # If there is a Unix epoch value to be replaced
    elif git cat-file -p "$hash" | grep -q '\<author\>\|\<committer\>'; then
        echo "git cat-file -p $hash > objects/$hash.txt"
        content=$(git cat-file -p "$hash")
        timestamp=$(echo "$content" | grep -Eo '[0-9]{10}' | head -1)
        new_content=$(echo "$content" | sed -E "s/(author|committer) ([^<]+) <[^>]+> ([0-9]+) ([+-][0-9]+)/\1 \2 '$(date -d @"$timestamp")' \4/g")
        if [ "$content" != "$new_content" ]; then
            echo "- converted Unix epoch values to datetime values"
        fi
        echo "$new_content" > objects/"$hash".txt

    # Regular file to copy
    else
        echo "git cat-file -p $hash > objects/$hash.txt"
        git cat-file -p "$hash" > objects/"$hash".txt
    fi
done

echo "Done"
