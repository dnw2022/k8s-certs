# https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough
# https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli

# https://trstringer.com/cheap-kubernetes-in-azure/
# https://medium.com/@casperrubaek/how-to-create-a-cheap-kubernetes-cluster-on-azure-for-learning-purposes-ec413a2b33e4
# https://stacksimplify.com/azure-aks/create-aks-cluster-using-az-aks-cli/

AKS_RESOURCE_GROUP=rg-dnw

AKS_SERVICE_PRINCIPAL_NAME=sp-dnw
AKS_SUBSCRIPTION_ID=45dad4eb-e885-48df-a5de-b1f9a02009b0
AKS_CONTRIBUTOR_ROLE_NAME=Contributor
AKS_CONTRIBUTOR_ROLE_ID=b24988ac-6180-42a0-ab88-20f7382dd24c

# Only this works with github actions
# See: https://github.com/Azure/login#configure-deployment-credentials
az ad sp create-for-rbac \
  --name $AKS_SERVICE_PRINCIPAL_NAME --role contributor \
  --scopes /subscriptions/$AKS_SUBSCRIPTION_ID/resourceGroups/$AKS_RESOURCE_GROUP \
  --sdk-auth

# Create a Service Principal (SP) with password based authentication (password will be in the json output)
# Somehow this does not work
# az ad sp create-for-rbac --name $AKS_SERVICE_PRINCIPAL_NAME --role $AKS_CONTRIBUTOR_ROLE_NAME

# Get ObjectId based on SP displayname
# Basic query: az ad sp list --filter "displayname eq '${AKS_SERVICE_PRINCIPAL_NAME}'" --query "[].{displayName:displayName, objectId:objectId}"
AKS_SERVICE_PRINCIPAL_OBJECT_ID=$(az ad sp list --filter "displayname eq '${AKS_SERVICE_PRINCIPAL_NAME}'" --query "[].{displayName:displayName, objectId:objectId}" | jq -r '.[0].objectId')

# Assign role to Resource Group
# This is not needed anymore, because we already specified --scopes with az ad sp create-for-rbac
# az role assignment create --assignee $AKS_SERVICE_PRINCIPAL_OBJECT_ID \
# --role $AKS_CONTRIBUTOR_ROLE_NAME \
# --resource-group $AKS_RESOURCE_GROUP

# Delete the SP
az ad sp delete --id $AKS_SERVICE_PRINCIPAL_OBJECT_ID

AKS_LOCATION=eastus
AKS_CLUSTERNAME=cluster-dnw-aks

az login

az group create --name $AKS_RESOURCE_GROUP --location $AKS_LOCATION

az ad sp list --all --query "[].{displayName:displayName, objectId:objectId}" --output tsv
az ad sp list --display-name "{displayName}"

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
 
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTERNAME

# For service account creation see:
# https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli#4-sign-in-using-a-service-principal



# https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli
az login --service-principal -u <app-id> -p <password-or-cert> --tenant <tenant>

az group delete --name $AKS_RESOURCE_GROUP --yes --no-wait