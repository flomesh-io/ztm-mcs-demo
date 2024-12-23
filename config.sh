#!/bin/bash

# Host IP
HOST_IP=$(ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}')

# Cluster names
CLUSTER1="cluster1"
CLUSTER2="cluster2"

# Docker network names
NETWORK1="cluster1-net"
NETWORK2="cluster2-net"

# API ports for clusters
API_PORT1=6550
API_PORT2=6551

# Test pod name
TEST_POD_NAME="test-pod"

# Hub + agent variables
ZTM_TAG="1.0.0-rc1"
HUB_IMAGE="flomesh/ztm-hub:${ZTM_TAG}"
AGENT_IMAGE="flomesh/ztm-agent:${ZTM_TAG}"
HUB_PORT=8888
HUB_CONTAINER_NAME="ztm-hub"
HUB_DATA_DIR="/tmp/ztm-hub-data"  # Local directory to store hub data
AGENT_PORT=7777
AGENT_CONFIGMAP_NAME="ztm-agent-permit"
AGENT_JOIN_MESH="mcs-mesh"


wait_for_pod() {
    local cluster_name=$1
    local pod_name=$2
    echo "Waiting for pod $pod_name to be in Running state in cluster $cluster_name..."

    # Wait for the pod to be in the 'Ready' state
    kubectl --context k3d-$cluster_name wait --for=condition=ready pod/$pod_name --timeout=300s

    if [ $? -eq 0 ]; then
        echo "Pod $pod_name is now running in cluster $cluster_name."
    else
        echo "Error: Pod $pod_name failed to become ready within the timeout."
    fi
}
