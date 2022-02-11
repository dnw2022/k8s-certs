# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
# https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html#create-service-role
# https://app.cnvrg.io/docs/guides/eks.html#create-a-user-in-aws-with-the-correct-permissions
# https://docs.aws.amazon.com/eks/latest/userguide/security_iam_service-with-iam.html
# https://eksctl.io/usage/creating-and-managing-clusters/

EKS_CLUSTERNAME=cluster-dnw-eks \
EKS_REGION=eu-central-1 \
EKS_NODEGROUP_NAME=ng-dnw

# create EKS cluster role
# https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html
eksctl create cluster \
  --name $EKS_CLUSTERNAME \
  --version 1.21 \
  --region $EKS_REGION \
  --nodegroup-name $EKS_NODEGROUP_NAME \
  --node-type t3.medium \
  --nodes 1 \
  --node-volume-type gp3 \
  --node-volume-size 60

# Follow the instructions in the README.md file to:
# (1) install ingress-nginx
# (2) install cert-manager
# (3) create cert-manager secret with the Cloudflare token

# Cleanup
# To get nodegroup name use:
# eksctl get nodegroup --cluster $EKS_CLUSTERNAME
# Delete the nodegroup
eksctl delete nodegroup \
  --cluster $EKS_CLUSTERNAME \
  --name $EKS_NODEGROUP_NAME \
  --region $EKS_REGION \
  --wait

# Delete the cluster
eksctl delete cluster \
  --name $EKS_CLUSTERNAME \
  --region $EKS_REGION \
  --wait