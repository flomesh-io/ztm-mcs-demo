#!/bin/bash

source config.sh

create_docker_network() {
    local network_name=$1
    if docker network inspect $network_name >/dev/null 2>&1; then
        echo "Docker network '$network_name' already exists. Skipping creation."
    else
        echo "Creating Docker network '$network_name'..."
        docker network create $network_name || { echo "Failed to create network $network_name"; exit 1; }
    fi
}

create_k3d_cluster() {
    local cluster_name=$1
    local api_port=$2
    local network_name=$3
    if k3d cluster list | grep -q "^$cluster_name "; then
        echo "k3d cluster '$cluster_name' already exists. Skipping creation."
    else
        echo "Creating k3d cluster '$cluster_name'..."
        k3d cluster create $cluster_name \
            --api-port $api_port \
            --network $network_name \
            --agents 0 \
            --servers 1 \
            --k3s-arg "--tls-san=$HOST_IP@server:0" \
            || { echo "Failed to create cluster '$cluster_name'"; exit 1; }
    fi
}

# Create Docker networks
create_docker_network $NETWORK1
create_docker_network $NETWORK2

# Create k3d clusters
create_k3d_cluster $CLUSTER1 $API_PORT1 $NETWORK1
create_k3d_cluster $CLUSTER2 $API_PORT2 $NETWORK2

# Verify clusters
echo "Verifying clusters..."
kubectl config set-cluster $CLUSTER1 --server https://$HOST_IP:$API_PORT1
kubectl config set-cluster $CLUSTER2 --server https://$HOST_IP:$API_PORT2

echo "Clusters created successfully."
echo "To access the clusters:"
echo "  kubectl config use-context k3d-$CLUSTER1"
echo "  kubectl config use-context k3d-$CLUSTER2"