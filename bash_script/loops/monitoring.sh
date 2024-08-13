#!/bin/bash
while true; do
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)"
    echo "Memory Usage:"
    free -m
    sleep 1
done
