#!/bin/bash
file="data.txt"
if [ -e "$file" ]; then
    cp "$file" "$file.bak"
    echo "Backup of $file created as $file.bak"
else
    echo "$file does not exist."
fi
