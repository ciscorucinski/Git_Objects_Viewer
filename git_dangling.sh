#!/bin/bash

mkdir -p dangling/blob
mkdir -p dangling/tree
mkdir -p dangling/commit

for hash in $(git fsck --lost-found | awk '/dangling/ {print $3}'); do
    type=$(git cat-file -t "$hash")

    # If the file is compressed it will find the '' character
    if git cat-file -p "$hash" | grep -q ''; then
        git cat-file -p "$hash" | zstd -d > dangling/"$type"/decoded-"$hash".txt
    else
        git cat-file -p "$hash" > dangling/"$type"/"$hash".txt
    fi
done
