# https://cloud.google.com/sdk/gcloud/reference/container/clusters/create
# https://gist.github.com/pydevops/cffbd3c694d599c6ca18342d3625af97
# gcloud container get-server-config (list available options)
GC_PROJECT_ID=noted-tempo-340906 \
GC_CLUSTERNAME=cluster-dnw-gcloud \
GC_ZONE=europe-west3-a \
GC_IMAGE_TYPE=COS_CONTAINERD \
# GC_MACHINE_TYPE=e2-micro gives insufficient memory error when installing ingress-nginx \
GC_MACHINE_TYPE=e2-small \
GC_NUM_NODES=1 \
GC_DISKTYPE=pd-standard \
GC_DISKSIZE=20

gcloud container clusters create $GC_CLUSTERNAME \
  --zone $GC_ZONE \
  --image-type $GC_IMAGE_TYPE \
  --machine-type $GC_MACHINE_TYPE \
  --num-nodes $GC_NUM_NODES \
  --disk-type $GC_DISKTYPE \
  --disk-size $GC_DISKSIZE

# https://cloud.google.com/iam/docs/creating-managing-service-accounts#iam-service-accounts-create-gcloud
# https://cloud.google.com/kubernetes-engine/docs/how-to/iam
# gcloud iam service-accounts list
GC_SERVICE_ACCOUNT_NAME=sa-dnw \
GC_ROLE_NAME=roles/container.clusterAdmin

# gcloud iam service-accounts list
# gcloud iam service-accounts describe
gcloud iam service-accounts create $GC_SERVICE_ACCOUNT_NAME \
  --display-name=$GC_SERVICE_ACCOUNT_NAME

GC_SERVICE_ACCOUNT_ID="$GC_SERVICE_ACCOUNT_NAME@$GC_PROJECT_ID.iam.gserviceaccount.com"

GC_SERVICE_ACCOUNT_MEMBER="serviceAccount:$GC_SERVICE_ACCOUNT_ID"
gcloud projects add-iam-policy-binding $GC_PROJECT_ID \
  --member=$GC_SERVICE_ACCOUNT_MEMBER \
  --role=$GC_ROLE_NAME

# gcloud projects remove-iam-policy-binding $GC_PROJECT_ID \
#   --member=$GC_SERVICE_ACCOUNT_MEMBER \
#   --role=$GC_ROLE_NAME

# gcloud projects get-iam-policy $GC_PROJECT_ID
# gcloud projects add-iam-policy-binding ${myproject} --member serviceAccount:${k10saemail} --role roles/compute.storageAdmin

# configure sdk to use cluster
# gcloud container clusters get-credentials $GC_CLUSTERNAME

# Create clusterrolebinding for service account, giving ClusterRole/cluster-admin
# Without this you will get authorization errors when trying to list resources in the cluster
# kubectl get clusterrolebindings
kubectl create clusterrolebinding sa-dnw-cluster-admin \
  --clusterrole cluster-admin \
  --user $GC_SERVICE_ACCOUNT_ID

gcloud iam service-accounts keys create "gksdk-$GC_SERVICE_ACCOUNT_NAME.json" \
  --iam-account=$GC_SERVICE_ACCOUNT_ID \
  --key-file-type=json
 
# Follow the instructions in the README.md file to:
# (1) install ingress-nginx
# (2) install cert-manager
# (3) create cert-manager secret with the Cloudflare token

# Cleanup
# gcloud iam service-accounts keys list --iam-account=$GC_SERVICE_ACCOUNT_ID
# gcloud iam service-accounts keys delete xxx --iam-account=$GC_SERVICE_ACCOUNT_ID
# gcloud iam service-accounts delete $GC_SERVICE_ACCOUNT_ID
# gcloud container clusters delete $GC_CLUSTERNAME
