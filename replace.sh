#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

command -v tput >/dev/null && TPUT=true

_echo() {
  if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
    echo -e "$(tput setaf $2)$1$(tput sgr0)"
  else
    echo -e "$1"
  fi
}

_warn() {
  echo
  _echo "- $@" 5
}

_result() {
  echo
  _echo "# $@" 4
}

_command() {
  echo
  _echo "$ $@" 3
}

_success() {
  echo
  _echo "+ $@" 2
  exit 0
}

_error() {
  echo
  _echo "- $@" 1
  exit 1
}

_replace() {
  if [ "${OS_NAME}" == "darwin" ]; then
    sed -i "" -e "$1" "$2"
  else
    sed -i -e "$1" "$2"
  fi
}

_find_replace() {
  _command "find . -name \"$2\" -exec sed -e \"$1\""
  _result "$(find . -name "$2" | wc -l | xargs) files matched \"$2\""

  if [ "${OS_NAME}" == "darwin" ]; then
    find . -name "$2" -exec sed -i "" -e "$1" {} \;
  else
    find . -name "$2" -exec sed -i -e "$1" {} \;
  fi
}

_main() {
  # variable
  _command "aws sts get-caller-identity"
  export ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account -r)

  _command "aws configure get region"
  export REGION="$(aws configure get region)"

  export BUCKET="terraform-workshop-${1:-${ACCOUNT_ID}}"

  export LOCK_TABLE="terraform-resource-lock"

  _result "ACCOUNT_ID = ${ACCOUNT_ID}"

  _result "REGION = ${REGION}"
  _result "BUCKET = ${BUCKET}"
  _result "LOCK_TABLE = ${LOCK_TABLE}"

  # create s3 bucket
  _command "aws s3 ls | grep ${BUCKET}"
  COUNT=$(aws s3 ls | grep ${BUCKET} | wc -l | xargs)
  if [ "x${COUNT}" == "x0" ]; then
    _command "aws s3 mb s3://${BUCKET}"
    aws s3 mb s3://${BUCKET} --region ${REGION}
  else
    _warn "s3 bucket ${BUCKET} already exists, skipped"
  fi

  # create dynamodb table
  _command "aws dynamodb list-tables | grep ${LOCK_TABLE}"
  COUNT=$(aws dynamodb list-tables | jq -r .TableNames | grep ${LOCK_TABLE} | wc -l | xargs)
  if [ "x${COUNT}" == "x0" ]; then
    _command "aws dynamodb create-table --table-name ${LOCK_TABLE}"
    aws dynamodb create-table \
      --table-name ${LOCK_TABLE} \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
      --region ${REGION} | jq .
  else
    _warn "dynamodb table ${LOCK_TABLE} already exists, skipped"
  fi

  # replace
  _find_replace "s/terraform-workshop-[[:alnum:]]*/${BUCKET}/g" "*.tf"

  _result "$(grep -rl "${BUCKET}" --include='*.tf' . 2>/dev/null | wc -l | xargs) *.tf files reference ${BUCKET}"

  _success "done"
}

_main
