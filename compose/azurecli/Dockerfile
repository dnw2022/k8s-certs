FROM mcr.microsoft.com/azure-cli
WORKDIR /app

# kubectl client version and kubernetes cluster version should not differ more than 1 minor version
RUN az aks install-cli --client-version 1.21

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh

RUN apk add bash-completion
# https://stedolan.github.io/jq/manual/#TypesandValues
RUN apk add jq

# Based on: https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/
# In this case there is already a .bashrc file 
# Without a starting newline characters it gets concatenated with the last existing line 
RUN printf '\nsource /usr/share/bash-completion/bash_completion' >> ~/.bashrc
RUN printf '\nsource <(kubectl completion bash)' >> ~/.bashrc
RUN printf '\nalias k=kubectl' >> ~/.bashrc
RUN printf '\ncomplete -F __start_kubectl k' >> ~/.bashrc