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
