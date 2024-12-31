# atlantis

* <https://github.com/terraform-aws-modules/terraform-aws-atlantis>

## aws ssm put

```bash
export GOOGLE_CLIENT_ID="REPLACE_ME"
export GOOGLE_CLIENT_SECRET="REPLACE_ME"

aws ssm put-parameter --name /common/google/client_id --value "${GOOGLE_CLIENT_ID}" --type SecureString --overwrite | jq .
aws ssm put-parameter --name /common/google/client_secret --value "${GOOGLE_CLIENT_SECRET}" --type SecureString --overwrite | jq .

aws ssm put-parameter --name /k8s/common/infracost/api-key --value "${ADMIN_PASSWORD}" --type SecureString --overwrite | jq .
aws ssm put-parameter --name /k8s/common/infracost/self-hosted-api-key --value "${ADMIN_PASSWORD}" --type SecureString --overwrite | jq .
aws ssm put-parameter --name /k8s/common/infracost/pricing-api-endpoint --value "${ADMIN_PASSWORD}" --type SecureString --overwrite | jq .
```

## aws ssm get

```bash
aws ssm get-parameter --name /common/google/client_id --with-decryption | jq .Parameter.Value -r
aws ssm get-parameter --name /common/google/client_secret --with-decryption | jq .Parameter.Value -r

aws ssm get-parameter --name /k8s/common/infracost/api-key --with-decryption | jq .Parameter.Value -r
aws ssm get-parameter --name /k8s/common/infracost/self-hosted-api-key --with-decryption | jq .Parameter.Value -r
aws ssm get-parameter --name /k8s/common/infracost/pricing-api-endpoint --with-decryption | jq .Parameter.Value -r
```
