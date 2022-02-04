# https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough
# https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli

# https://trstringer.com/cheap-kubernetes-in-azure/
# https://medium.com/@casperrubaek/how-to-create-a-cheap-kubernetes-cluster-on-azure-for-learning-purposes-ec413a2b33e4
# https://stacksimplify.com/azure-aks/create-aks-cluster-using-az-aks-cli/

# Define variables
AKS_RESOURCE_GROUP=rg-dnw \
AKS_SERVICE_PRINCIPAL_NAME=sp-dnw \
AKS_SUBSCRIPTION_ID=45dad4eb-e885-48df-a5de-b1f9a02009b0 \
AKS_CONTRIBUTOR_ROLE_NAME=Contributor \
AKS_CONTRIBUTOR_ROLE_ID=b24988ac-6180-42a0-ab88-20f7382dd24c \
AKS_LOCATION=eastus \
AKS_CLUSTERNAME=cluster-dnw-aks \

# Create resource group
az group create --name $AKS_RESOURCE_GROUP --location $AKS_LOCATION

# See https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli#4-sign-in-using-a-service-principal
# Create Service Principal (SP)
# Only this works with github actions
# See: https://github.com/Azure/login#configure-deployment-credentials
# Note that the --scope option is necessary to be able to use this in github actions (login will fail if not supplied)
# This is because the json that is logged to the console will be missing some information without the --scope option 
az ad sp create-for-rbac \
  --name $AKS_SERVICE_PRINCIPAL_NAME --role contributor \
  --scopes /subscriptions/$AKS_SUBSCRIPTION_ID/resourceGroups/$AKS_RESOURCE_GROUP \
  --sdk-auth

# Delete the SP
# First you need to get ObjectId based on SP displayname
# Basic query: az ad sp list --filter "displayname eq '${AKS_SERVICE_PRINCIPAL_NAME}'" --query "[].{displayName:displayName, objectId:objectId}"
# AKS_SERVICE_PRINCIPAL_OBJECT_ID=$(az ad sp list --filter "displayname eq '${AKS_SERVICE_PRINCIPAL_NAME}'" --query "[].{displayName:displayName, objectId:objectId}" | jq -r '.[0].objectId')
# Then you can delete it
# az ad sp delete --id $AKS_SERVICE_PRINCIPAL_OBJECT_ID

# Create the cluster
# Note that the options in the cheap options for node-vm-size (< 4 vCPUs) cannot be selected when you create the cluster in the azure portal
# This is by design according to an incident
# You can work around it in the portal by adjusting the system node pool on de second tab though ;) 
az aks create \
    -g $AKS_RESOURCE_GROUP \
    -n $AKS_CLUSTERNAME \
    --load-balancer-sku basic \
    --enable-managed-identity \
    --location $AKS_LOCATION \
    --node-vm-size Standard_B2s \
    --min-count 1 \
    --max-count 1 \
    --node-osdisk-size 30 \
    --network-plugin kubenet \
    --node-count 1 \
    --generate-ssh-keys \
    --enable-cluster-autoscaler \

# To delete the resource group (and the kubernetes cluster in it)
# The first time I executed this command nothing seemed to happen
# Then I removed the --yes and --no-wait options and that seemed to work fine
# az group delete --name $AKS_RESOURCE_GROUP --yes --no-wait