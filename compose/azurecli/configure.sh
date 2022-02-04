# $1 => $AKS_RESOURCE_GROUP
# $2 => $AKS_CLUSTERNAME
# $3 => $AKS_APP_ID
# $4 => $AKS_PASSWORD
# $5 => $AKS_TENANT_ID

# https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli
# To login (non-interactive)
az login --service-principal -u $3 -p $4 --tenant $5

# To initialize the az cli for working with the cluster
# This also configures things so kubectl works 
az aks get-credentials --resource-group $1 --name $2