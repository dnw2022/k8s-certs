# $1 => $DO_ACCESS_TOKEN
# $2 => $DO_CLUSTER_NAME

doctl auth init -t $1
doctl kubernetes cluster kubeconfig save $2