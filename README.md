# terraform-env-demo

## replace

> Create bucket and dynamodb for Terraform backend.

```bash
# aws sts get-caller-identity

./replace.sh

# ACCOUNT_ID = 123456789012
# REGION = ap-northeast-2
# BUCKET = terraform-workshop-123456789012
```

## for containerd-config

```bash
aws ssm put-parameter --name "/k8s/common/containerd-config" --value ""  --type SecureString --overwrite | jq .
```

## for atlantis

```bash
export GITHUB_USERNAME="nalbam"

aws ssm put-parameter --name "/common/github/$GITHUB_USERNAME/token" --value ""  --type SecureString --overwrite | jq .

aws ssm put-parameter --name "/common/google/client_id" --value ""  --type SecureString --overwrite | jq .
aws ssm put-parameter --name "/common/google/client_secret" --value ""  --type SecureString --overwrite | jq .

aws ssm put-parameter --name "/k8s/common/infracost/api-key" --value ""  --type SecureString --overwrite | jq .
aws ssm put-parameter --name "/k8s/common/infracost/self-hosted-api-key" --value ""  --type SecureString --overwrite | jq .
aws ssm put-parameter --name "/k8s/common/infracost/pricing-api-endpoint" --value ""  --type SecureString --overwrite | jq .
```
