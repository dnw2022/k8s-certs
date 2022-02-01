# Useful reading

https://stackoverflow.com/questions/51613842/wildcard-ssl-certificate-with-subdomain-redirect-in-kubernetes

# Building, running and pushing default-backend locally

docker build -f Dockerfile.dev -t dnw2022/default-backend .
docker run  -p 8000:5000 dnw2022/default-backend
docker push dnw2022/default-backend

# GKE deploy with service account in github actions

create a service-account for the kubernetes cluster and download the json file with the keypair. Then base64 encode it like this: 

cat multi-k8s-339908-e1853ea369e6.json | base64

Add the base64 encoded string as a github secret