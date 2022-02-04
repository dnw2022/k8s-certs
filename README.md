# Git remote with username

You can specify a git username for the git remote like this:

```
git remote add origin https://{username}@github.com/dnw2022/k8s-certs.git
```

# Building, running and pushing default-backend locally

```
docker build -f Dockerfile.dev -t dnw2022/default-backend .
docker run -p 8000:5000 dnw2022/default-backend
```

# Viewing kubernetes object yaml

```
kubectl get deployment {deploymentname} -o yaml
```

# GKE deploy with service account in github actions

```
DOCKER_HUB_TOKEN = {docker pwd}  
GKE_PROJECT_ID = multi-k8s-339908  
GKE_SERVICE_ACCOUNT_KEY_FILE_JSON = cat multi-k8s-339908-e1853ea369e6.json | base64  
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

Make sure to use the correct token type in the issuers (apiTokenSecretRef or apiKeySecretRef):

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

Letsencrypt has quite strict rate limit, so be sure to test certificate issuing first with their staging environment.

You can switch between issuers by chagning the annotation in both the ingress-default-dotnet-works-com.yml and ingress-default-freelancedirekt.yml file.

For staging use:

```
cert-manager.io/cluster-issuer: 'letsencrypt-staging'
```

And for production:

```
cert-manager.io/cluster-issuer: 'letsencrypt-prod'
```

Note that after a deploy the certificate used will be automatically picked up by ingress-nginx, so there is no need to restart anything.

# Cert-manager troubleshooting

kubectl describe is very useful for troubleshooting.

```
kubectl get certificates


| NAME                            | READY | SECRET                          | AGE |
----------------------------------| ----- | ------------------------------- | --- |
| xxx-wildcard-tls                | True  | xxx-wildcard-tls                | 5s | 
```

if there is alreadu a secret for the certificate nothing will be done.

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

If everything is ok kubectl get certificates will show READY (true) again and will show the name of the SECRET:

```
kubectl get certificates

| NAME                            | READY | SECRET                          | AGE |
----------------------------------| ----- | ------------------------------- | --- |
| xxx-wildcard-tls                | True  | xxx-wildcard-tls                | 5s | 
```

Now follow the chain CertificateRequest (cr), Order and Challenge. You might also need to check the logs of the cert-manager pod in the cert-manager namespace:

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

Looking at the logs of the cert-manager pod is also useful sometimes:

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

| Type  | Name | Content            | Proxy status  | TTL
| ------| -----| -------------------| ------------  | -
| A     | test | {LoadBalancer IP}  | DNS only      | Auto

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

# Digital Ocean Kurnetes Service (DOKS) doctl using docker image

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

# Azure Kurnetes Service (AKS) az cli using docker image

https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough
https://trstringer.com/cheap-kubernetes-in-azure/

To create a new cluster see compose/azurecli/create-cluster.sh file   

```
docker-compose down --remove-orphans
docker-compose build
source ~/.secrets/.all
ID=$(docker-compose run -d --rm azurecli)
docker exec $ID /bin/bash /src/configure.sh $AKS_RESOURCE_GROUP $AKS_CLUSTERNAME $AKS_APP_ID $AKS_PASSWORD $AKS_TENANT_ID
docker exec -it $ID bash
docker-compose kill azurecli

Manual setup in the container (after docker exec -it $ID bash above):

# Interactive login with more right!
# The login in the configure.sh script uses the Service Principal (SP)
# You will need to use this for example when you create the cluster with the commands in compose/azurecli/create-cluster.sh
az login

# configuring the cluster to use once it was created
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTERNAME
``` 

# Switching between GKE, DOKS and AKS

Just point to the DOKS or GKE load balancer in the Cloudflare portal or temporarily update your /etc/hosts file

# LoadBalancer public ip

```
k get service
```

Find the service of type LoadBalancer and you will find the public IP address in the EXTERNAL-IP column:  

| NAME                                    | TYPE            | CLUSTER-IP    | EXTERNAL-IP   | PORT(S)                     | AGE
| -                                       | -               | -             | -             | -                          | -
| my-release-ingress-nginx-controller     | LoadBalancer    | 10.0.97.119   | 40.121.242.61 | 80:32663/TCP,443:32442/TCP  | 38m

# Testing if it works

Either update your /etc/hosts file or add a Cloudflare A record that points to the load balancer public IP.  

Note that navigating to https://example.dotnet-works.com/ works:  

Hmmm, it seems you ventured into unknown territory :(  

But https://example.dotnet-works.com/aass gives:  

Cannot GET /aass  

This is correct behavior. Nginx is doing the right thing, but the default-backend nodejs express server that it forwards the request to gives this message because it only handles /.   

# Example ingress config

The k8s/ingress-example-dotnet-works-com.yml file contains an example of an Ingress service.  

The example configures https://example.dotnet-works.com/ with the default backend.

# Letsencrypt rate limits

If you try to issue too many certificates using the letsencrypt production environment you will get an error like this:  

too many certificates (5) already issued for this exact set of domains in the last 168 hours.    

You can try and copy the certificate from another kubernetes environment.  

In the kubenetes environment where the certificate is available:  

```
kubectl get secret xxx-wildcard-tls -o yaml > xxx-wildcard-tls-secret.yml
```

To make it available in the host file system:

```
mv xxx-wildcard-tls-secret.yml /src
```

Then copy the certificate over, delete the old secret and create the new one by applying the yml file:  

```
mv /src/xxx-wildcard-tls-secret.yml .
delete secrets xxx-wildcard-tls
kubectl apply -f xxx-wildcard-tls-secret.yml
```

After a while the certificate READY flag should change from FALSE to True:

| NAME                            | READY | SECRET                          | AGE |
----------------------------------| ----- | ------------------------------- | --- |
| xxx-wildcard-tls                | True  | xxx-wildcard-tls                | 5s | 

You can force the process by deleting the certificate object:

```
kubectl delete certificate xxx-wildcard-tls
```

Its good practice to keep the issued certificates somewhere safe, since you cannot re-issue them easily. The old certificates will remain valid unless revoked.

# Invalid TLS certificates

If you see certificate errors its most likely because the certificate was issued by the letsencrypt staging environment.

You will see something like "(Staging) Pretend Pear X1 certificate not trusted" when inspecting the certificate in the browser.

# Github Actions issue with installing doctl

Manually installing doctl during the build/deploy process like below does not work
In the next deployment step the shell script cannot find doctl  
I am not sure where to install things so they can be found in next steps

See: https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action

The yml from do.yml

```
- name: Install & configure tools
  run: |-
    # Install kubectl
    # curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/v1.23.3/bin/linux/amd64/kubectl"
    chmod +x kubectl

    # Install doctl
    curl -LO "https://github.com/digitalocean/doctl/releases/download/v1.70.0/doctl-1.70.0-linux-amd64.tar.gz"
    tar -xf doctl-1.70.0-linux-amd64.tar.gz
    chmod +x doctl
    export PATH=$PATH:$(pwd)

- name: Install & configure tools
  run: |-
    # Configure doctl
    # Here you will get an error that doctl cannot be found
    doctl
    doctl auth init -t "${{ env.DO_ACCESS_TOKEN }}"
    doctl kubernetes cluster kubeconfig save ${{ env.DO_CLUSTER_NAME }}
```