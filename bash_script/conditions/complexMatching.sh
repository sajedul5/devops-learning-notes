#!/bin/bash

echo "Choose an option:"
echo "1. Start"
echo "2. Stop"
echo "3. Restart"
read option
case $option in
    1)
        echo "Starting..."
        ;;
    2)
        echo "Stopping..."
        ;;
    3)
        echo "Restarting..."
        ;;
    *)
        echo "Invalid option"
        ;;
esac
