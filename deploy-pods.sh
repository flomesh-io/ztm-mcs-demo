#!/bin/bash

source config.sh

deploy_pod_to_cluster() {
    local cluster_name=$1
    echo "Deploying pipy service to $cluster_name..."
    kubectl --context k3d-$cluster_name apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pipy
  labels:
    app: pipy
spec:
  containers:
  - name: pipy
    image: flomesh/pipy-nightly:latest
    ports:
    - name: pipy
      containerPort: 8080
    command:
    - pipy
    - -e
    - |
      pipy()
      .listen(8080)
      .serveHTTP(new Message('Hi, I am running on $cluster_name'))
EOF
    
    echo "test-server pod created in $cluster_name."
    wait_for_pod $cluster_name "pipy"
    kubectl --context k3d-$cluster_name expose pod pipy --name=pipy --port=8080 --target-port=8080 --type=ClusterIP
}

create_tunnel() {
    echo "Creating outbound tunnel for pipy on cluster-1"
    kubectl --context k3d-cluster1 exec ztm-agent -- ztm tunnel open outbound tcp/pipy --targets pipy:8080
    echo "Creating inbound tunnel for remote pipy on cluster-2"
    kubectl --context k3d-cluster2 exec ztm-agent -- ztm tunnel open inbound tcp/pipy --listen 0.0.0.0:8082
}

setup_proxy() {
    echo "Creating ztm proxy forwarding rules on cluster2"
    kubectl --context k3d-cluster2 exec -it ztm-agent -- ztm proxy config --add-target 0.0.0.0/0 '*'
    echo ""
    echo "Creating listening side on cluster1"
    kubectl --context k3d-cluster1 exec -it ztm-agent -- ztm proxy config --set-listen 0.0.0.0:8082
}

create_curl_pod() {
    local cluster_name=$1
    echo "Creating curl pod in $cluster_name..."
    kubectl --context k3d-$cluster_name apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: curl
  labels:
    app: curl
spec:
  containers:
  - image: curlimages/curl
    imagePullPolicy: IfNotPresent
    name: curl
    command: ["sleep", "365d"]
EOF

    echo "Curl pod created in $cluster_name."
    wait_for_pod $cluster_name "curl"
}


create_delegate_svc() {
echo "Creating delegate svc in cluster2..."
kubectl --context k3d-cluster2 apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: tunnel1
spec:
  selector:
    app: ztm-agent
  ports:
    - port: 8080
      targetPort: 8082
EOF
}

create_proxy_svc() {
echo "Creating delegate svc in cluster2..."
kubectl --context k3d-cluster1 apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: proxy2
spec:
  selector:
    app: ztm-agent
  ports:
    - port: 8080
      targetPort: 8082
EOF
}

perform_test() {
    echo "\n\n ******** Performing local and remote test **********\n"
    echo "Accessing cluster local test-service"
    kubectl --context k3d-cluster2 exec -it curl -- curl pipy:8080
    echo ""
    echo "Accesss cluster-1 test service locally on cluster-2"
    kubectl --context k3d-cluster2 exec -it curl -- curl tunnel1:8080
    echo ""
    echo "Accessing cluster local test-service on cluster1"
    kubectl --context k3d-cluster1 exec -it curl -- curl pipy:8080
    echo ""
    echo "Accessing test service on cluster2 from cluster1 via ztm proxy"
    kubectl --context k3d-cluster1 exec -it curl -- curl -x http://proxy2:8080 http://pipy:8080
}

for cluster in $CLUSTER1 $CLUSTER2; do
    deploy_pod_to_cluster $cluster
    create_curl_pod $cluster
    
done

create_tunnel
create_delegate_svc
setup_proxy
create_proxy_svc

perform_test