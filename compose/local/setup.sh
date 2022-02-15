#!/bin/bash

# Delete current kind cluster and ignore errors if it doesn't exist
kind delete cluster --name kind 2>/dev/null

# Ask for keychain password for certificate secrets early on
DNW_CERT_SECRET=$(security find-generic-password -w -s 'secret_dotnetworks_com_wildcard' -a '$(id -un)' | base64 --decode)
FLD_CERT_SECRET=$(security find-generic-password -w -s 'secret_freelancedirekt_nl_wildcard' -a '$(id -un)' | base64 --decode)

# Create the new cluster with a private container / image registry
. ./kind_create_cluster_with_registry.sh

# Pull necessary images and store on the cluster node

# 1. ingress-nginx
docker pull k8s.gcr.io/ingress-nginx/controller:v1.1.1
kind load docker-image k8s.gcr.io/ingress-nginx/controller:v1.1.1

# 2. cert-manager
docker pull quay.io/jetstack/cert-manager-cainjector:v1.7.1
kind load docker-image quay.io/jetstack/cert-manager-cainjector:v1.7.1

docker pull quay.io/jetstack/cert-manager-controller:v1.7.1
kind load docker-image quay.io/jetstack/cert-manager-controller:v1.7.1

docker pull quay.io/jetstack/cert-manager-webhook:v1.7.1
kind load docker-image quay.io/jetstack/cert-manager-webhook:v1.7.1

# Install ingress-nginx in cluster
# https://kind.sigs.k8s.io/docs/user/ingress/
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

sleep 10

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Setup istio
. ./istio/setup.sh

# Install cert-manager in cluster
# https://artifacthub.io/packages/helm/cert-manager/cert-manager
# Install with helm and override clusterResourceNamespace so the istio-system namespace is used for storing certs and secrets
# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.7.1 \
  --set installCRDs=true
  #--set clusterResourceNamespace=istio-system (might not be useful)

sleep 10

kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=90s

# Build images
TAG=localhost:5001/default-backend:latest
docker build -t $TAG -f ../../default-backend/Dockerfile  ../../default-backend
docker push $TAG

# Store certificate secrets
# If using cert-manager in combination with the istio gateway (instead of ingress-nginx) the secrets
# for the certificates need to be in the namespace where the istio gateway is running
echo "Storing DNW cert secret"
kubectl apply -f <(echo "$DNW_CERT_SECRET") --namespace=default
echo "Storing FLD cert secret"
kubectl apply -f <(echo "$FLD_CERT_SECRET") --namespace=default

# Install app specific objects in cluster
helm upgrade default-backend ../../k8s/helm/default-backend --install
helm upgrade cert-issuers ../../k8s/helm/cert-issuers --install
helm upgrade default-ingress ../../k8s/helm/default-ingress --install

# Restart dpeloyments
kubectl rollout restart deployment default-backend-deployment