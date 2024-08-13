#!/bin/bash

# add_numbers() {
#     local sum=$(( $1 + $2 ))
#     echo "The sum of $1 and $2 is: $sum"
# }

# add_numbers 5 10


# get_current_time() {
#     echo $(date +"%T")
# }

# current_time=$(get_current_time)
# echo "The current time is: $current_time"


hello() {

    local a=$1
    local b=$2
    echo "$a $b"
}

hello Good Morning
