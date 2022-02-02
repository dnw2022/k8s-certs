# $GKE_TOKEN expected as first argument
# $GKE_PROJECT_ID expected as second argument
# $GKE_ZONE expected as 3rd argument
# $GKE_CLUSTER_NAME expected as 4th argument

#gcloud auth login
echo $1 | base64 -d > ./service-account.json
gcloud auth activate-service-account --key-file service-account.json
gcloud config set project $2
gcloud config set compute/zone $3
gcloud container clusters get-credentials $4
echo 'alias k="kubectl"' > ~/.bashrc