#!/bin/bash

print_array() {
    local array=("$@")
    for element in "${array[@]}"; do
        echo "$element"
    done
}

my_array=("apple" "banana" "cherry")
print_array "${my_array[@]}"


