# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

#https://app.cnvrg.io/docs/guides/eks.html#create-a-user-in-aws-with-the-correct-permissions

# create EKS cluster role
# https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html#create-service-role

# https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html
eksctl create cluster \
  --name cluster-dnw-eks \
  --version 1.21 \
  --region eu-central-1 \
  --node-type t4g.small \
  --nodes 1 \
  --node-volume-type gp3 \
  --node-volume-size 20

# https://docs.aws.amazon.com/eks/latest/userguide/security_iam_service-with-iam.html

# https://eksctl.io/usage/creating-and-managing-clusters/