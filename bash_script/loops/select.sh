#!/bin/bash
PS3="Please choose an option: "
options=("Start" "Stop" "Status" "Quit")

select opt in "${options[@]}"; do
    case $opt in
        "Start")
            echo "Starting service..."
            # Start service command
            ;;
        "Stop")
            echo "Stopping service..."
            # Stop service command
            ;;
        "Status")
            echo "Service status:"
            # Status command
            ;;
        "Quit")
            break
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
