#!/bin/bash

# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION=1.13.0

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
docker pull docker.io/querycapistio/proxyv2:$VERSION
kind load docker-image docker.io/querycapistio/proxyv2:$VERSION

docker pull docker.io/querycapistio/pilot:$VERSION
kind load docker-image docker.io/querycapistio/pilot:$VERSION

# 2. Istio sample application (all x64 giving errors when loading using kind)
# docker pull docker.io/istio/examples-bookinfo-details-v1:1.16.2
# kind load docker-image docker.io/istio/examples-bookinfo-details-v1:1.16.2

# docker pull docker.io/istio/examples-bookinfo-productpage-v1:1.16.2
# kind load docker-image docker.io/istio/examples-bookinfo-productpage-v1:1.16.2

# docker pull docker.io/istio/examples-bookinfo-ratings-v1:1.16.2
# kind load docker-image docker.io/istio/examples-bookinfo-ratings-v1:1.16.2

# docker pull docker.io/istio/examples-bookinfo-reviews-v1:1.16.2
# kind load docker-image docker.io/istio/examples-bookinfo-reviews-v1:1.16.2

# docker pull docker.io/istio/examples-bookinfo-reviews-v2:1.16.2
# kind load docker-image docker.io/istio/examples-bookinfo-reviews-v2:1.16.2

# docker pull docker.io/istio/examples-bookinfo-reviews-v3:1.16.2
# kind load docker-image docker.io/istio/examples-bookinfo-reviews-v3:1.16.2

# 3. Istio add-ons
docker pull grafana/grafana:8.3.1
kind load docker-image grafana/grafana:8.3.1

# no arm64 version for 1.23 (for later versions there is)
docker pull docker.io/jaegertracing/all-in-one:1.29
kind load docker-image docker.io/jaegertracing/all-in-one:1.29

docker pull quay.io/kiali/kiali:v1.45
kind load docker-image quay.io/kiali/kiali:v1.45

docker pull jimmidyson/configmap-reload:v0.5.0
kind load docker-image jimmidyson/configmap-reload:v0.5.0

# Install istio
istioctl install -f "$SCRIPT_DIR/install_istio.yml" -y

# Label default namespace
kubectl label namespace default istio-injection=enabled --overwrite

# Install example
#kubectl apply -f ~/istio-1.12.3/samples/bookinfo/platform/kube/bookinfo.yaml
#kubectl apply -f ~/istio-1.12.3/samples/bookinfo/networking/bookinfo-gateway.yaml

# Install istio add-ons
kubectl apply -f ~/istio-$VERSION/samples/addons
#kubectl rollout status deployment/kiali -n istio-system