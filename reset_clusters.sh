#!/bin/bash

source config.sh

remove_hub() {
    # Stop and remove the ztm-hub container from the host
    echo "Stopping and removing ztm-hub container..."
    docker stop $HUB_CONTAINER_NAME >/dev/null 2>&1
    docker rm $HUB_CONTAINER_NAME >/dev/null 2>&1
    echo "ztm-hub container stopped and removed."

    # Optionally remove the hub's data directory
    echo "Removing hub data directory $HUB_DATA_DIR (optional)..."
    rm -rf $HUB_DATA_DIR
}

cleanup() {
    echo "Starting cleanup of clusters and host..."

    for cluster in $CLUSTER1 $CLUSTER2; do
        echo "Cleaning resources in $cluster..."
        
        # Delete the ztm-agent pod
        echo "Deleting ztm-agent pod in $cluster..."
        kubectl --context k3d-$cluster delete pod ztm-agent --ignore-not-found

        # Delete the ztm-agent service
        echo "Deleting ztm-agent service in $cluster..."
        kubectl --context k3d-$cluster delete svc ztm-agent --ignore-not-found

        # Optionally clean other resources like ConfigMaps, if needed
        echo "Deleting ConfigMap $AGENT_CONFIGMAP_NAME in $cluster..."
        kubectl --context k3d-$cluster delete configmap $AGENT_CONFIGMAP_NAME --ignore-not-found

        # Additional cleanups: Remove custom resources like pipy or curl pods/services if required
        echo "Deleting other pods and services (optional)..."
        kubectl --context k3d-$cluster delete pod curl pipy --ignore-not-found
        kubectl --context k3d-$cluster delete svc pipy tunnel1 --ignore-not-found
    done

    echo "Cleanup completed."
}

cleanup