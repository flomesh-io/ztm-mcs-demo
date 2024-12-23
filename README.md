# Kubernetes Multi-Cluster Communication with ZTM: Isolation and Security

This demo showcases the setup of two isolated Kubernetes clusters using k3d, enhanced with Zero Trust Networking (ZTM). It demonstrates secure inter-cluster communication using ZTM Tunnels and Proxies, while maintaining default isolation between clusters. The deployment includes sample HTTP services and testing tools to validate connectivity, highlighting the principles of secure, scalable, and decentralized networking.

## HOW-TO

This guide walks you through setting up and testing two isolated Kubernetes clusters using k3d, configuring Zero Trust Networking with ZTM (Zero Trust Mesh), and deploying sample test services. 


## Architecture

```
+------------------------------------------------+
|                Host Machine                    |
| +--------------------------------------------+ |
| |                ZTM Hub                     | |
| | - Runs in Docker container                 | |
| | - Exposes port for communication           | |
| +--------------------------------------------+ |
+------------------------------------------------+
           |                                      |
           | Communication (Cluster ↔ Host)       |
           |                                      |
+-------------------+                +-------------------+
|    Cluster1       |                |    Cluster2       |
| +---------------+ |                | +---------------+ |
| | ZTM Agent     | |                | | ZTM Agent     | |
| | - Connects to | |                | | - Connects to | |
| |   ZTM Hub     | |                | |   ZTM Hub     | |
| +---------------+ |                | +---------------+ |
|                   |                |                   |
| +---------------+ |                | +---------------+ |
| | HTTP Service  | |                | | ZTM Proxy     | |
| | (Pipy/pjs)    | |                | | - Routes      | |
| +---------------+ |                | |   traffic     | |
|                   |                | +---------------+ |
| +---------------+ |                | +---------------+ |
| | Curl Pod      | |                | | Curl Pod      | |
| +---------------+ |                | +---------------+ |
+-------------------+                +-------------------+
           ^                                      ^
           |                                      |
           | ZTM Tunnel                           | ZTM Tunnel
           +--------------------------------------+
                          Secure Communication
           |                                      |
           | <------- ZTM Proxy Routing --------> |
           |    Proxy on Cluster2 routes traffic  |
           |    for services in Cluster1          |
           +--------------------------------------+

```

## Prerequisites

Before you begin, ensure the following are installed on your machine:

* **Docker**: For running containers.
* **k3d**: For creating lightweight Kubernetes clusters.
* **kubectl**: For interacting with Kubernetes clusters.

## Setting Up Two Isolated Kubernetes Clusters with k3d

Run the provided setup script to create two isolated Kubernetes clusters (`cluster1` and `cluster2`):

```sh
./setup.sh
```

After the script completes, verify that both clusters are up and ready:

```sh
for cluster in cluster1 cluster2; do
    echo "Checking nodes in $cluster"
    kubectl --context k3d-$cluster get nodes -o wide
done
```

## Connectivity Check

The following connectivity tests will be performed:

1. **Cluster ↔ Host**: Verifies that each cluster can communicate with the host machine.
2. **Cluster1 ↔ Cluster2**: Verifies that there is no direct communication between the two clusters.

Run the connectivity script to validate these expectations. The first test should succeed, while the second test should fail (indicating isolation between clusters).

```sh
./connectivity_test.sh
```

## Setting Up ZTM (Zero Trust Mesh)

Run the following script to configure ZTM components:

```sh
./ztm-hub-agents.sh
```

This script performs the following actions:

* Sets up a **ZTM Hub** as a Docker container on the host machine and exposes its port. The `--names` option for ZTM Hub is set to the host machine's IP address.
* Deploys **ZTM Agents** in both Kubernetes clusters.

## Deploying Test Services

Use the script below to deploy the following test services:

1. **Sample HTTP Service**: A simple HTTP server implemented using Pipy (pjs).
2. **Curl Pod**: For testing HTTP requests.

Additionally, the script sets up:

1. **ZTM Tunnel**: Enables secure communication between the two clusters.
2. **ZTM Proxy**: Allows services in one cluster to use the proxy in the other cluster for accessing resources.

Run the deployment script:

```sh
./deploy-pods.sh
```

### Testing Connectivity

After deployment, the following connectivity tests will be performed:

1. **ZTM Tunnel**: Validate that services on `cluster1` can be accessed securely from `cluster2` via the tunnel.
2. **ZTM Proxy**: Confirm that `cluster1` services can use the proxy on `cluster2` to reach their destinations.

## Resetting Clusters (Optional)

If needed, reset the clusters to their initial state (removing all deployed resources without terminating the Kubernetes clusters):

```sh
./reset_clusters.sh
```