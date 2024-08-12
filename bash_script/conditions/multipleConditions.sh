#!/bin/bash

file="test.txt"
if [ -e "$file" ] && [ -w "$file" ]; then
    echo "File exists and is writable"
else
    echo "File doesn't exist or isn't writable"
fi
