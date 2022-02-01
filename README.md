# Useful reading

https://stackoverflow.com/questions/51613842/wildcard-ssl-certificate-with-subdomain-redirect-in-kubernetes

# Building, running and pushing default-backend locally

docker build -f Dockerfile.dev -t dnw2022/default-backend .
docker run  -p 8000:5000 dnw2022/default-backend
docker push dnw2022/default-backend

# GKE deploy with service account in github actions

DOCKER_HUB_TOKEN = <docker pwd>
GKE_PROJECT_ID = multi-k8s-339908
GKE_SERVICE_ACCOUNT_KEY_FILE_JSON = cat multi-k8s-339908-e1853ea369e6.json | base64

# GKE sdk using docker image

docker-compose --file docker-compose.gksdk.yml run --rm gksdk

gcloud auth login
gcloud config set project multi-k8s-339908
gcloud config set compute/zone europe-central2-a
gcloud container clusters get-credentials multi-cluster
alias k="kubectl"

# Cloudflare token

kubectl create secret generic cloudflare-api-key-secret -n cert-manager --from-literal api-key=xxx

Make sure to use the correct token type in the issuers:

apiTokenSecretRef:
  name: cloudflare-api-key-secret
  key: api-key

or:

apiKeySecretRef:
  name: cloudflare-api-key-secret
  key: api-key