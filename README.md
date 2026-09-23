# terraform-env-demo

## Agent Studio storage

`demo/4-role/policies/agent-studio.json` scopes object access to Studio's artifact,
image and private source prefixes. Bucket-level `s3:ListBucket` is also required
for the importer to distinguish a missing object from denied access during `HeadObject`;
without it S3 returns 403 for a new file. It grants key listing in `agent-studio-static`,
not object reads outside the existing prefixes. See [S3 HeadObject permissions](https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html).

## replace

> Create bucket and dynamodb for Terraform backend.

```bash
# aws sts get-caller-identity

./replace.sh

# ACCOUNT_ID = 123456789012
# REGION = ap-northeast-2
# BUCKET = terraform-workshop-123456789012
```
