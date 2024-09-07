#!/bin/bash

# Script to test load balancing between frontend-service pods. Got 33/32/32 for 3 frontend replicas

# Configuration
SERVICE_NAME="frontend-service"   # Replace with your service name
NAMESPACE="default"               # Replace with your namespace if different
TOTAL_REQUESTS=1000               # Total number of requests to send
CONCURRENT_REQUESTS=10            # Number of concurrent requests

# Get the service external IP or NodePort
SERVICE_IP=$(minikube service frontend-service --url)

# Simulate traffic with Apache Benchmark
echo "Simulating $TOTAL_REQUESTS requests with $CONCURRENT_REQUESTS concurrent requests..."
ab -n $TOTAL_REQUESTS -c $CONCURRENT_REQUESTS $SERVICE_IP/ > result.txt

# Get pod names
PODS=$(kubectl get pods -n $NAMESPACE -l app=frontend -o jsonpath='{.items[*].metadata.name}')

# Initialize request counts
declare -A POD_REQUESTS
for POD in $PODS; do
  POD_REQUESTS[$POD]=0
done

# Function to count requests in pod logs
count_requests_in_pod() {
  local pod=$1
  local count=$(kubectl logs $pod -n $NAMESPACE | grep -c 'GET' || true)
  echo $count
}

# Count requests for each pod
for POD in $PODS; do
  REQUEST_COUNT=$(count_requests_in_pod $POD)
  POD_REQUESTS[$POD]=$REQUEST_COUNT
done

# Calculate total requests
TOTAL_REQUEST_COUNT=0
for COUNT in "${POD_REQUESTS[@]}"; do
  TOTAL_REQUEST_COUNT=$((TOTAL_REQUEST_COUNT + COUNT))
done

# Display results
echo "Requests distribution:"
for POD in "${!POD_REQUESTS[@]}"; do
  REQUEST_COUNT=${POD_REQUESTS[$POD]}
  PERCENTAGE=$(echo "scale=2; ($REQUEST_COUNT / $TOTAL_REQUEST_COUNT) * 100" | bc)
  echo "$POD: $PERCENTAGE% of requests"
done
