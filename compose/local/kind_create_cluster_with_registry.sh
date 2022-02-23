# For mapping extra port ranges: https://github.com/kubernetes-sigs/kind/issues/1789
#!/bin/zsh

HTTP_CONTAINER_PORT=$1
echo "HTTP_CONTAINER_PORT=${HTTP_CONTAINER_PORT}"

HTTPS_CONTAINER_PORT=$2
echo "HTTPS_CONTAINER_PORT=${HTTPS_CONTAINER_PORT}"

set -o errexit
# https://kind.sigs.k8s.io/docs/user/local-registry/

# create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
  podSubnet: "10.240.0.0/16"
  serviceSubnet: "10.0.0.0/16"
  disableDefaultCNI: true
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
    - containerPort: ${HTTP_CONTAINER_PORT}
      hostPort: 80
      listenAddress: "0.0.0.0"
      protocol: TCP
    - containerPort: ${HTTPS_CONTAINER_PORT}
      hostPort: 443
      listenAddress: "0.0.0.0"
      protocol: TCP
    - containerPort: 30002
      hostPort: 15021
      listenAddress: "0.0.0.0"
      protocol: TCP
    - containerPort: 30080
      hostPort: 30080
      listenAddress: "0.0.0.0"
      protocol: TCP
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:5000"]
EOF

# connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

