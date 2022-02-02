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

# Helm installation

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Ingress-nginx installation using helm

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install my-release ingress-nginx/ingress-nginx

# Cert-manager installation using help

https://cert-manager.io/docs/

kubectl namespace create cert-manager
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.7.0 \
  --set installCRDs=true

# Cert-manager and Ingress

We have 2 options for issuing certificates:

(1) Use the ingress annotation cert-manager.io/cluster-issuer: 'letsencrypt-prod'. This will use ingress-shim to automatically create 
Certificate objects
(2) Create Certificate objects in our cluster manually and let cert-manager go through the process of issuing them and storing them as secrets in our cluster

# Cloudflare tokens

Make sure to use the correct token type in the issuers (apiTokenSecretRef or apiKeySecretRef)

apiTokenSecretRef:
  name: cloudflare-api-token-secret
  key: api-token

api-token => kubectl create secret generic cloudflare-api-token-secret -n cert-manager --from-literal api-token=xxx

or:

apiKeySecretRef:
  name: cloudflare-api-key-secret
  key: api-key

api-key => kubectl create secret generic cloudflare-api-key-secret -n cert-manager --from-literal api-key=xxx

IMPORTANT: the secret has to be in the cert-manager namespace. Hence -n cert-manager

# Cert-manager troubleshooting

kubectl describe is your friend:

kubectl get certificates 
kubecrl describe certifcate (this will show the CertificateRequest object that was created near the bottom)

Now follow the chain CertificateRequest (cr), Order and Challenge. You might also need to check the logs of the cert-manager pod in the cert-manager namespace

# Restart a deployment

kubectl rollout restart deployment/my-release-ingress-nginx-controller

# Cloudflare configuration

To point test.freelancedirekt.nl to the cluster:

Type  Name  Content            Proxy status  TTL
A     test  <LoadBalancer IP>  DNS only      Auto