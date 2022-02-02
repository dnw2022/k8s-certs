FROM google/cloud-sdk:alpine
WORKDIR /app

RUN gcloud components install kubectl

RUN curl -LO "https://github.com/digitalocean/doctl/releases/download/v1.70.0/doctl-1.70.0-linux-arm64.tar.gz"
RUN tar -xf doctl-1.70.0-linux-arm64.tar.gz
RUN chmod +x doctl
RUN mv ./doctl /usr/local/bin
RUN doctl version