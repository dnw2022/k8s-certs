#!/bin/bash

# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION=1.15.0

# The uses preview arm64 docker hub images from docker.io/querycapistio 
# The latest version available now (Feb 22, 2022) is 1.13.0
# The istioctl version is used to determine the versionm of the images to pull
# so you have to install version 1.13.0 of the cli fitrst with
# curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.13.0 sh -
# ISTIO_VERSION=1.13.0

# istioctl install --set hub=docker.io/querycapistio --set profile=demo -y

# kind create cluster --config=single-node.yaml

# Pull and load images
# 1. Istio
docker pull docker.io/istio/pilot:$VERSION
kind load docker-image docker.io/istio/pilot:$VERSION

docker pull docker.io/istio/proxyv2:$VERSION
kind load docker-image docker.io/istio/proxyv2:$VERSION

docker pull docker.io/calico/cni:v3.24.1
kind load docker-image docker.io/calico/cni:v3.24.1

docker pull docker.io/calico/node:v3.24.1
kind load docker-image docker.io/calico/node:v3.24.1

# 3. Istio add-ons
docker pull grafana/grafana:9.0.1
kind load docker-image grafana/grafana:9.0.1

docker pull docker.io/jaegertracing/all-in-one:1.35
kind load docker-image docker.io/jaegertracing/all-in-one:1.35

docker pull quay.io/kiali/kiali:v1.55
kind load docker-image quay.io/kiali/kiali:v1.55

docker pull prom/prometheus:v2.34.0
kind load docker-image prom/prometheus:v2.34.0

docker pull jimmidyson/configmap-reload:v0.5.0
kind load docker-image jimmidyson/configmap-reload:v0.5.0

# Install istio (arm64 natively supported as of version 1.15!)
istioctl install -f "$SCRIPT_DIR/install_istio.yml" -y
# istioctl install --set profile=demo -y
# istioctl install -y

# Label default namespace
kubectl label namespace default istio-injection=enabled --overwrite

# Install example (not working on arm64)
#kubectl apply -f ~/istio-1.15.0/samples/bookinfo/platform/kube/bookinfo.yaml
#kubectl apply -f ~/istio-1.15.0/samples/bookinfo/networking/bookinfo-gateway.yaml

# Install istio add-ons
kubectl apply -f ~/istio-$VERSION/samples/addons
#kubectl rollout status deployment/kiali -n istio-system