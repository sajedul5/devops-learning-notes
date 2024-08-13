#!/bin/bash
# Declare an array
# fruits=("apple" "banana" "cherry")

# # Loop through the array
# for fruit in "${fruits[@]}"; do
#     echo "Fruit: $fruit"
# done


colors=("red" "green" "blue")

# Loop through the array indices
for index in "${!colors[@]}"; do
    echo "Color at index $index: ${colors[$index]}"
done
