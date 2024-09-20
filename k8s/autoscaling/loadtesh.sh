#!/bin/bash

# Load test parameters
URL="http://localhost:8000/"
NUM_REQUESTS=1000000
CONCURRENT_REQUESTS=10

# Function to send a single request
send_request() {
  response=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  echo "Response Code: $response"
}

# Start load test in background
echo "Starting load test with $NUM_REQUESTS requests..."
pids=()
for ((i=1; i<=NUM_REQUESTS; i++)); do
  send_request &  # Send request in background
  pids+=($!)      # Store the process ID

  # Check if we've reached the concurrency limit
  if ((i % CONCURRENT_REQUESTS == 0)); then
    # Wait for all background processes to finish
    for pid in "${pids[@]}"; do
      wait $pid
    done
    # Clear the array for the next batch
    pids=()
  fi
done

# Wait for any remaining requests
for pid in "${pids[@]}"; do
  wait $pid
done

echo "Load test completed!"

# # Monitor HPA in a separate loop
# HPA_NAME="python-app-hpa"  # Change to your HPA name
# echo "Monitoring HPA status..."

# while true; do
#   kubectl get hpa "$HPA_NAME"
#   sleep 5  # Refresh every 5 seconds
# done
