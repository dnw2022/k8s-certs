FROM ubuntu:18.04

WORKDIR /app

RUN apt update && apt upgrade
RUN apt-get -y install curl
RUN apt-get -y install unzip
RUN apt-get -y install groff
RUN apt-get -y install nano

RUN curl -o "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
RUN unzip awscliv2.zip
RUN ./aws/install -i /usr/local/aws-cli -b /usr/local/bin;

RUN curl -fsSL -o kubectl "https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/arm64/kubectl"
RUN chmod +x kubectl
RUN mv ./kubectl /usr/local/bin

RUN curl -fsSL -o eksctl.tar.gz "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_arm64.tar.gz"
RUN tar x -f eksctl.tar.gz
RUN chmod +x eksctl
RUN mv ./eksctl /usr/local/bin

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh

RUN apt-get install bash-completion
RUN echo 'source /usr/share/bash-completion/bash_completion' >>~/.bashrc source /usr/share/bash-completion/bash_completion
RUN echo 'source <(kubectl completion bash)' >> ~/.bashrc
RUN echo 'alias k=kubectl' >> ~/.bashrc
RUN echo 'complete -F __start_kubectl k' >> ~/.bashrcaws

RUN echo '. <(eksctl completion bash)' >> ~/.bashrc