# https://docs.digitalocean.com/reference/doctl/reference/kubernetes/cluster/create/

# Define variables
DO_CLUSTER_NAME=cluster-dnw \
DO_NODE_COUNT=1 \
DO_REGION=fra1 \
DO_NODE_SIZE=s-2vcpu-4gb \
DO_REGISTRY_NAME=dnw2022 \
DO_REGISTRY_SUBSCRIPTION_TIER=starter

# Create private container registry
doctl registry create $DO_REGISTRY_NAME \
  --subscription-tier $DO_REGISTRY_SUBSCRIPTION_TIER

# Create kubernetes cluster
doctl kubernetes cluster create $DO_CLUSTER_NAME \
  --count $DO_NODE_COUNT \
  --region $DO_REGION \
  --size $DO_NODE_SIZE

# Allow the kubernetes cluster to pull images from the 
# https://github.com/digitalocean/doctl/issues/847
doctl kubernetes cluster registry add $DO_REGISTRY_NAME
# This does not seem to work 
# doctl registry kubernetes-manifest | kubectl apply -f -

# follow the instructions in the README.md file to:
# (1) install ingress-nginx
# (2) install cert-manager
# (3) create cert-manager secret with the Cloudflare token

# Cleanup
# doctl kubernetes cluster registry remove $DO_CLUSTER_NAME
# doctl registry delete