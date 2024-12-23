#!/bin/bash

source config.sh

# Function to deploy a test pod in a cluster
deploy_test_pod() {
    local context=$1
    echo "Deploying test pod in context $context..."
    kubectl --context $context run $TEST_POD_NAME --image=alpine --restart=Never -- sleep 3600
    echo "Waiting for the pod to be ready..."
    kubectl --context $context wait --for=condition=Ready pod/$TEST_POD_NAME --timeout=30s
}

# Function to get the IP address of a test pod
get_pod_ip() {
    local context=$1
    echo "Retrieving IP address of test pod in context $context..."
    kubectl --context $context get pod $TEST_POD_NAME -o jsonpath='{.status.podIP}'
}

# Function to test connectivity from a pod
test_connectivity() {
    local context=$1
    local target=$2
    local description=$3

    echo "Testing connectivity from context $context to $target ($description)..."
    kubectl --context $context exec $TEST_POD_NAME -- ping -c 3 $target && \
        echo "SUCCESS: Connectivity to $description ($target) works!" || \
        echo "FAILURE: Connectivity to $description ($target) failed."
}

# Deploy test pods in both clusters
deploy_test_pod k3d-$CLUSTER1
deploy_test_pod k3d-$CLUSTER2

# Get pod IPs
POD_IP_CLUSTER1=$(get_pod_ip k3d-$CLUSTER1)
POD_IP_CLUSTER2=$(get_pod_ip k3d-$CLUSTER2)

if [ -z "$POD_IP_CLUSTER1" ] || [ -z "$POD_IP_CLUSTER2" ]; then
    echo "Failed to retrieve one or both Pod IPs. Exiting."
    exit 1
fi

echo "Cluster 1 Pod IP: $POD_IP_CLUSTER1"
echo "Cluster 2 Pod IP: $POD_IP_CLUSTER2"

# Test connectivity from cluster1
test_connectivity k3d-$CLUSTER1 $HOST_IP "host machine"
test_connectivity k3d-$CLUSTER1 $POD_IP_CLUSTER2 "test pod in cluster2"

# Test connectivity from cluster2
test_connectivity k3d-$CLUSTER2 $HOST_IP "host machine"
test_connectivity k3d-$CLUSTER2 $POD_IP_CLUSTER1 "test pod in cluster1"

# Clean up test pods
echo "Cleaning up test pods..."
kubectl --context k3d-$CLUSTER1 delete pod/$TEST_POD_NAME --ignore-not-found
kubectl --context k3d-$CLUSTER2 delete pod/$TEST_POD_NAME --ignore-not-found

echo "Connectivity test completed."
