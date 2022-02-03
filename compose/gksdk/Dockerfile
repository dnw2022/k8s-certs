FROM google/cloud-sdk:latest

WORKDIR /app

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh

RUN apt-get install bash-completion
RUN echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc source /usr/share/bash-completion/bash_completion
RUN echo 'source <(kubectl completion bash)' >> ~/.bashrc
RUN echo 'alias k=kubectl' >> ~/.bashrc
RUN echo 'complete -F __start_kubectl k' >> ~/.bashrc
