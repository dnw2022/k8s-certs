# Building, running and pushing default-backend locally

```
docker build -f Dockerfile.dev -t dnw2022/default-backend .  
docker run -p 8000:5000 dnw2022/default-backend  
docker push dnw2022/default-backend  
```

# Viewing kubernetes object yaml

```
kubectl get deployment {deploymentname} -o yaml
```

# GKE deploy with service account in github actions

```
DOCKER_HUB_TOKEN = {docker pwd}  
GKE_PROJECT_ID = multi-k8s-339908  
GKE_SERVICE_ACCOUNT_KEY_FILE_JSON = cat   multi-k8s-339908-e1853ea369e6.json | base64  
```

# GKE sdk using docker image

Manually configure container to manage cluster:

```
docker-compose run --rm gksdk
gcloud auth login  
gcloud config set project multi-k8s-339908  
gcloud config set compute/zone europe-central2-a  
gcloud container clusters get-credentials multi-cluster  
```

More automated way to configure container to manage cluster:

```
docker-compose down --remove-orphans
docker-compose build
source ~/.secrets/.all
ID=$(docker-compose run -d --rm gksdk)
docker exec $ID /bin/bash /src/configure.sh $GKE_TOKEN $GKE_PROJECT_ID $GKE_ZONE $GKE_CLUSTER_NAME
docker exec -it $ID bash
docker-compose kill gksdk
```

# Helm installation

Note that the docker image used for connecting to the cluster (GKE and DOKS) already has helm installed.

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

# Ingress-nginx installation using helm

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx  
helm install my-release ingress-nginx/ingress-nginx  
```

# Cert-manager installation using help

https://cert-manager.io/docs/

```
kubectl create namespace cert-manager

helm repo add jetstack https://charts.jetstack.io
helm repo update 
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.7.0 \
  --set installCRDs=true  
```

# Cert-manager and Ingress

We have 2 options for issuing certificates:

(1) Use the ingress annotation cert-manager.io/cluster-issuer: 'letsencrypt-prod'. This will use ingress-shim to automatically create 
Certificate objects  
(2) Create Certificate objects in our cluster manually and let cert-manager go through the process of issuing them and storing them as secrets in our cluster  

Useful reading: https://stackoverflow.com/questions/51613842/wildcard-ssl-certificate-with-subdomain-redirect-in-kubernetes  

# Cloudflare tokens

Create Cloudflare API token in their Management portal with these permissions:

| Token name	      | Permissions	                      | Resources	
| -                 | -                                 | - 
| {token name}	    | Zone.Zone (Read), Zone.DNS (Edit)	| Include (All zones)

Make sure to use the correct token type in the issuers (apiTokenSecretRef or apiKeySecretRef)  

```
apiTokenSecretRef:
  name: cloudflare-api-token-secret
  key: api-token
```

```
kubectl create secret generic cloudflare-api-token-secret -n cert-manager --from-literal api-token={your api token}
```

or:  

```
apiKeySecretRef:
  name: cloudflare-api-key-secret
  key: api-key
```

```
kubectl create secret generic cloudflare-api-key-secret -n cert-manager --from-literal api-key={your api key}
```

IMPORTANT: the secret has to be in the cert-manager namespace. Hence -n cert-manager  

# Letsencrypt staging vs production

Letsencrypt has quite strict rate limit, so be sure to test certificate issuing first with their staging environment  

You can switch between issuers by chagning the annotation in both the ingress-default-dotnet-works-com.yml and ingress-default-freelancedirekt.yml file  

For staging use:

```
cert-manager.io/cluster-issuer: 'letsencrypt-staging'
```

And for production:

```
cert-manager.io/cluster-issuer: 'letsencrypt-prod'
```

# Cert-manager troubleshooting

kubectl describe is very useful for troubleshooting  

```
kubectl get certificates


| NAME                            | READY | SECRET                          | AGE |
----------------------------------| ----- | ------------------------------- | --- |
| xxx-wildcard-tls                | True  | xxx-wildcard-tls                | 5s | 
```

if there is alreadu a secret for the certificate nothing will be done  

but if you delete the secret:  

```
kubectl delete secret xxx-wildcard-tls
```

```
kubectl get certificates

| NAME                            | READY | SECRET                          | AGE |
----------------------------------| ----- | ------------------------------- | --- |
| xxx-wildcard-tls                | False | xxx-wildcard-tls                | 5s | 
```

The whole flow will be initiated:

(1) create CertificateRequest  
(2) create Order  
(3) create Challenge  

If everything is ok kubectl get certificates will show READY (true) again and will show the name of the SECRET

```
kubectl get certificates

| NAME                            | READY | SECRET                          | AGE |
----------------------------------| ----- | ------------------------------- | --- |
| xxx-wildcard-tls                | True  | xxx-wildcard-tls                | 5s | 
```

Now follow the chain CertificateRequest (cr), Order and Challenge. You might also need to check the logs of the cert-manager pod in the cert-manager namespace  

```
root@ae8e6b45056d:/app# k get certificates

NAME                              READY   SECRET                            AGE
xxx-wildcard-tls                  True    xxx-wildcard-tls                  25h

root@ae8e6b45056d:/app# k describe certificates xxx-wildcard-tls | grep CertificateRequest
  
Normal  Requested  50s   cert-manager  Created new CertificateRequest resource "xxx-wildcard-tls-sb2h5"

root@ae8e6b45056d:/app# k describe cr xxx-wildcard-tls-sb2h5 | grep Order

Normal  OrderCreated       3m45s  cert-manager  Created Order resource default/xxx-wildcard-tls-sb2h5-3623495960
Normal  OrderPending       3m45s  cert-manager  Waiting on certificate issuance from order default/xxx-wildcard-tls-sb2h5-3623495960: ""

```

Usually in the order you will see that a Challende was created. You can again describe the Challenge, etc.

Looking at the logs of the cert-manager pod is also useful sometimes

```
root@ae8e6b45056d:/app# k get pods -n cert-manager 

NAME                                       READY   STATUS    RESTARTS      AGE
cert-manager-847544bbd-gxj94               1/1     Running   1 (47h ago)   2d
cert-manager-cainjector-5c747645bf-rrhz9   1/1     Running   5 (47h ago)   2d
cert-manager-webhook-f588b48b8-6h2vk       1/1     Running   0             2d

root@ae8e6b45056d:/app# k logs cert-manager-847544bbd-gxj94 -n cert-manager --tail=2 

I0203 08:02:41.669895       Last event
I0203 08:02:41.670523       Another event
```

# Restart a deployment

```
kubectl rollout restart deployment/my-release-ingress-nginx-controller  
```

# Cloudflare configuration

To point test.freelancedirekt.nl to the cluster:  

| Type  | Name | Content            | Proxy status  | TTL   |
| ------| -----| -------------------| ------------  | ----- |
| A     | test | {LoadBalancer IP}  | DNS only      | Auto

# Digital Ocean Kurnetes Service (DOKS)

```
docker-compose down --remove-orphans  
docker-compose build  
source ~/.secrets/.all  
ID=$(docker-compose run -d --rm doctl)  
docker exec $ID /bin/bash /src/configure.sh $DO_ACCESS_TOKEN $DO_CLUSTER_NAME  
docker exec -it $ID bash  
docker-compose kill doctl  
```

(doctl is the service in the docker-compose file!)  

It is also possible to install doctl locally and switch context (between kubernetes on Docker Desktop and DOKS)  