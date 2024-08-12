#!/bin/bash
read -p "Enter your username: " user
if [[ "$user" == "admin" || "$user" == "root" ]]; then
    echo "You have administrative privileges"
else
    echo "You are a regular user"
fi
