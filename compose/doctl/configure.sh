# $DO_ACCESS_TOKEN expected as first argument
# $DO_CLUSTER_NAME expected as second argument
doctl auth init -t $1
doctl kubernetes cluster kubeconfig save $2
echo 'alias k="kubectl"' > ~/.bashrc