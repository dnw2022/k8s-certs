# $1 => $EKS_CLUSTERNAME
# $2 => $EKS_REGION
# $3 => EKS_ACCESS_KEY
# $4 => EKS_ACCESS_KEY_SECRET

# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-methods

# You need to create a new user with a access_key and secret 
# In the AWS console go to IAM -> users and click "Add users"
# Choose programmatic access and attach existing policies directly
# Choose the AdministratorAccess policy and click next twice
# When you click on the created user you can generate access keys on the "Security credentials" tab with "Create access key"

# aws configure list
# stored here: ls -la ~/.aws in the configuration and crednetials files
aws configure set region $2
aws configure set aws_access_key_id $3
aws configure set aws_secret_access_key $4
aws configure set output json
eksctl utils write-kubeconfig --cluster $1 --region $2

# Test if access is ok
# eksctl get cluster