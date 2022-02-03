FROM google/cloud-sdk:latest

WORKDIR /app

RUN curl -LO "https://github.com/digitalocean/doctl/releases/download/v1.70.0/doctl-1.70.0-linux-arm64.tar.gz"
RUN tar -xf doctl-1.70.0-linux-arm64.tar.gz
RUN chmod +x doctl
RUN mv ./doctl /usr/local/bin
RUN doctl version

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh

RUN apt-get install bash-completion
RUN echo 'source /usr/share/bash-completion/bash_completion' >>~/.bashrc source /usr/share/bash-completion/bash_completion
RUN echo 'source <(kubectl completion bash)' >> ~/.bashrc
RUN echo 'alias k=kubectl' >> ~/.bashrc
RUN echo 'complete -F __start_kubectl k' >> ~/.bashrc