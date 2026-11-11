#!/usr/bin/env bash
# Points this repository at the authenticated AWS account: creates the Terraform state bucket
# and replaces the previous account ID in every tracked file.
set -euo pipefail

for command in aws git jq; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

cd "$(dirname "$0")"
[[ -f demo/2-vpc/02-backend.tf ]] || { echo "demo/2-vpc/02-backend.tf not found" >&2; exit 1; }

account_id="$(aws sts get-caller-identity --output json | jq -r '.Account')"
[[ "$account_id" =~ ^[0-9]{12}$ ]] || { echo "Could not determine AWS account ID" >&2; exit 1; }
region="${AWS_REGION:-${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null || true)}}"
[[ "$region" == "ap-northeast-2" ]] || {
  echo "This repository configures Terraform backends in ap-northeast-2; refusing region '${region}'" >&2
  exit 1
}

# The state bucket name carries the account ID the code currently points at.
previous_id="$(sed -nE 's/^ +bucket += "terraform-workshop-([0-9]{12})"$/\1/p' demo/2-vpc/02-backend.tf)"
[[ "$previous_id" =~ ^[0-9]{12}$ ]] || { echo "Could not read the current account ID from demo/2-vpc/02-backend.tf" >&2; exit 1; }
bucket="terraform-workshop-${account_id}"

printf 'AWS account: %s (code currently uses %s)\nRegion: %s\nTerraform state bucket: %s\n' \
  "$account_id" "$previous_id" "$region" "$bucket"

if aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  echo "S3 bucket already exists; keeping it."
else
  aws s3api create-bucket --bucket "$bucket" --region "$region" \
    --create-bucket-configuration "LocationConstraint=$region" >/dev/null
fi

aws s3api put-public-access-block --bucket "$bucket" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-encryption --bucket "$bucket" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-bucket-versioning --bucket "$bucket" \
  --versioning-configuration Status=Enabled

# Keep old state versions for recovery, but not forever. An existing lifecycle configuration is left
# untouched because a put would replace all of its rules.
if aws s3api get-bucket-lifecycle-configuration --bucket "$bucket" >/dev/null 2>&1; then
  echo "S3 bucket lifecycle configuration exists; keeping it."
else
  aws s3api put-bucket-lifecycle-configuration --bucket "$bucket" --lifecycle-configuration '{
    "Rules": [{
      "ID": "expire-noncurrent-state",
      "Status": "Enabled",
      "Filter": {},
      "NoncurrentVersionExpiration": {"NoncurrentDays": 90},
      "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 7}
    }]
  }'
fi

if [[ "$previous_id" != "$account_id" ]]; then
  while IFS= read -r -d '' file; do
    if [[ "$(uname -s)" == "Darwin" ]]; then
      sed -i '' "s/${previous_id}/${account_id}/g" "$file"
    else
      sed -i "s/${previous_id}/${account_id}/g" "$file"
    fi
  done < <(git grep -lz -F "$previous_id")

  if git grep -n -F "$previous_id"; then
    echo "The previous account ID $previous_id remains in the files above." >&2
    exit 1
  fi
fi

git diff --stat
printf 'Updated account %s references and configured the S3 state bucket.\n' "$account_id"
