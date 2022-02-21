#!/bin/bash

INGRESS=istio
PRELOAD_IMAGES=true
STORE_CERT_SECRETS=true
CERT_SECRETS_NAMESPACE=istio-system
HTTP_CONTAINER_PORT=30000
HTTPS_CONTAINER_PORT=30001

while [[ "$#" -gt 0 ]]
  do
    case $1 in
      -i|--ingress)
        INGRESS=$2

        if [ $INGRESS != "istio" ]
        then
          CERT_SECRETS_NAMESPACE=default
          HTTP_CONTAINER_PORT=80
          HTTPS_CONTAINER_PORT=443
        fi
        ;;
      -p|--preloadImages)
        PRELOAD_IMAGES=$2
        ;;
      -s|--storeCertificateSecrets)
        STORE_CERT_SECRETS=$2
        ;;
    esac
    shift
  done

# Delete current kind cluster and ignore errors if it doesn't exist
echo "Delete existing KinD cluster"
kind delete cluster --name kind 2>/dev/null

# Ask for keychain password for certificate secrets early on
if [ $STORE_CERT_SECRETS ]
then
  echo "Get cert secrets from keychain"

  if [[ "$OSTYPE" == "linux-gnu"* ]]
  then
    DNW_CERT_SECRET=$(cat ~/.secrets/dnw_cer_secret.yml)
    FLD_CERT_SECRET=$(cat ~/.secrets/fld_cer_secret.yml)
  else
    DNW_CERT_SECRET=$(security find-generic-password -w -s 'secret_dotnetworks_com_wildcard' -a '$(id -un)' | base64 --decode)
    FLD_CERT_SECRET=$(security find-generic-password -w -s 'secret_freelancedirekt_nl_wildcard' -a '$(id -un)' | base64 --decode)
  fi
fi

# Create the new cluster with a private container / image registry
echo "Create new KinD cluster"
. ./kind_create_cluster_with_registry.sh $HTTP_CONTAINER_PORT $HTTPS_CONTAINER_PORT

if [ $INGRESS = "istio" ]
then
  echo "Install istio in cluster"
  . ./istio/setup.sh
else
  # Install ingress-nginx in cluster
  # https://kind.sigs.k8s.io/docs/user/ingress/
  echo "Install ingress-nginx in cluster"
  if [ $PRELOAD_IMAGES ]
  then
    echo "Preload ingress-nginx images"
    docker pull k8s.gcr.io/ingress-nginx/controller:v1.1.1
    kind load docker-image k8s.gcr.io/ingress-nginx/controller:v1.1.1
  fi

  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

  sleep 10

  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s
fi

# Install cert-manager in cluster
# https://artifacthub.io/packages/helm/cert-manager/cert-manager
# Install with helm and override clusterResourceNamespace so the istio-system namespace is used for storing certs and secrets
# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml

if [ $PRELOAD_IMAGES ]
then
  echo "Preload cert-manager images"
  docker pull quay.io/jetstack/cert-manager-cainjector:v1.7.1
  kind load docker-image quay.io/jetstack/cert-manager-cainjector:v1.7.1

  docker pull quay.io/jetstack/cert-manager-controller:v1.7.1
  kind load docker-image quay.io/jetstack/cert-manager-controller:v1.7.1

  docker pull quay.io/jetstack/cert-manager-webhook:v1.7.1
  kind load docker-image quay.io/jetstack/cert-manager-webhook:v1.7.1
fi

echo "Install cert-manager in cluster"

# https://cert-manager.io/docs/usage/gateway/
# not working at the moment because istio does not support setting tls.mode to TERMINATE at the moment
# kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.3.0" | kubectl apply -f -

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.7.1 \
  --set installCRDs=true
  # --set "extraArgs={--feature-gates=ExperimentalGatewayAPISupport=true}"

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
if [ $STORE_CERT_SECRETS ]
then
  echo "Store certificate secrets in cluster"
  kubectl apply -f <(echo "$DNW_CERT_SECRET") --namespace=$CERT_SECRETS_NAMESPACE
  kubectl apply -f <(echo "$FLD_CERT_SECRET") --namespace=$CERT_SECRETS_NAMESPACE
fi

# Install app specific objects in cluster
echo "Install default-backend in cluster"
helm upgrade default-backend ../../k8s/helm/default-backend \
  --set PrivateContainerRegistry="localhost:5001/" \
  --install

echo "Install cert-issuers in cluster"
helm upgrade cert-issuers ../../k8s/helm/cert-issuers --install

if [ $INGRESS = "istio" ]
then
  echo "Configure istio gateway in cluster"
  helm upgrade default-ingress ../../k8s/helm/default-ingress --install
else
  echo "Configure ingress-nginx controller in cluster"
  helm upgrade default-ingress ../../k8s/helm/default-ingress \
    --set IngressEnabled=true \
    --set IngressNamespace=default \
    --set IstioGatewayEnabled=false \
    --install
fi

# Restart deployments
echo "Restart default-backend-deployment"
kubectl rollout restart deployment default-backend-deployment