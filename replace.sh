#!/usr/bin/env bash
set -euo pipefail

command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

identity="$(aws sts get-caller-identity --output json)"
account_id="$(jq -r '.Account' <<<"$identity")"
[[ "$account_id" =~ ^[0-9]{12}$ ]] || { echo "Could not determine AWS account ID" >&2; exit 1; }
region="${AWS_REGION:-${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null || true)}}"
[[ -n "$region" ]] || { echo "Set AWS_REGION, AWS_DEFAULT_REGION, or the AWS CLI default region" >&2; exit 1; }
[[ "$region" == "ap-northeast-2" ]] || { echo "This repository configures Terraform backends in ap-northeast-2; refusing region $region" >&2; exit 1; }
[[ -d demo && -r demo ]] || { echo "Run replace.sh from the repository root: demo/ not found or not readable" >&2; exit 1; }

bucket="terraform-workshop-${1:-$account_id}"
if [[ "$bucket" != "terraform-workshop-${account_id}" ]]; then
  echo "Refusing bucket '$bucket': it must match the authenticated account $account_id" >&2
  exit 1
fi

printf 'AWS account: %s\nRegion: %s\nTerraform state bucket: %s\n' "$account_id" "$region" "$bucket"

if aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  echo "S3 bucket already exists; keeping it."
else
  if [[ "$region" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$bucket" --region "$region"
  else
    aws s3api create-bucket --bucket "$bucket" --region "$region" \
      --create-bucket-configuration "LocationConstraint=$region"
  fi
fi

aws s3api put-public-access-block --bucket "$bucket" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-encryption --bucket "$bucket" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-bucket-versioning --bucket "$bucket" \
  --versioning-configuration Status=Enabled

replace_bucket() {
  local file="$1"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sed -i '' -E "s/terraform-workshop-[[:alnum:]-]+/${bucket}/g" "$file"
  else
    sed -i -E "s/terraform-workshop-[[:alnum:]-]+/${bucket}/g" "$file"
  fi
}

while IFS= read -r -d '' file; do
  replace_bucket "$file"
done < <(find demo -type f -name '*.tf' -print0)

printf 'Updated Terraform backend bucket references and enabled S3 state versioning.\n'
