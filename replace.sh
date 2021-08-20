#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

# variable
export ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account -r)

export REGION="$(aws configure get region)"
export BUCKET="terraform-workshop-${1:-${ACCOUNT_ID}}"

export LOCK_TABLE="terraform-resource-lock"

command -v tput > /dev/null && TPUT=true

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
    if [ "${OS_NAME}" == "darwin" ]; then
        find . -name "$2" -exec sed -i "" -e "$1" {} \;
    else
        find . -name "$2" -exec sed -i -e "$1" {} \;
    fi
}

_main() {
    _result "ACCOUNT_ID = ${ACCOUNT_ID}"

    _result "REGION = ${REGION}"
    _result "BUCKET = ${BUCKET}"

    _result "ROOT_DOMAIN = ${ROOT_DOMAIN}"
    _result "BASE_DOMAIN = ${BASE_DOMAIN}"

    if [ "${BASE_DOMAIN}" == "" ]; then
        _warn "BASE_DOMAIN is empty."
    fi

    # replace
    _find_replace "s/terraform-workshop-[[:alnum:]]*/${BUCKET}/g" "*.tf"

    if [ "${BASE_DOMAIN}" != "" ]; then
      _find_replace "s/demo.spic.me/${BASE_DOMAIN}/g" "*.tf"
      _find_replace "s/demo.spic.me/${BASE_DOMAIN}/g" "*.yaml"
      _find_replace "s/demo.spic.me/${BASE_DOMAIN}/g" "*.json"
    fi

    if [ "${ROOT_DOMAIN}" != "" ]; then
      _find_replace "s/spic.me/${ROOT_DOMAIN}/g" "*.tf"
    fi

    _find_replace "s/ADMIN_USERNAME/${ADMIN_USERNAME}/g" "*.tf"
    _find_replace "s/ADMIN_PASSWORD/${ADMIN_PASSWORD}/g" "*.tf"

    _find_replace "s/GOOGLE_CLIENT_ID/${GOOGLE_CLIENT_ID}/g" "*.json"
    _find_replace "s/GOOGLE_CLIENT_SECRET/${GOOGLE_CLIENT_SECRET}/g" "*.json"

    _find_replace "s|SLACK_TOKEN|${SLACK_TOKEN}|g" "*.tf"

    # create s3 bucket
    COUNT=$(aws s3 ls | grep ${BUCKET} | wc -l | xargs)
    if [ "x${COUNT}" == "x0" ]; then
        _command "aws s3 mb s3://${BUCKET}"
        aws s3 mb s3://${BUCKET} --region ${REGION}
    fi

    # create dynamodb table
    COUNT=$(aws dynamodb list-tables | jq -r .TableNames | grep ${LOCK_TABLE} | wc -l | xargs)
    if [ "x${COUNT}" == "x0" ]; then
        _command "aws dynamodb create-table --table-name ${LOCK_TABLE}"
        aws dynamodb create-table \
            --table-name ${LOCK_TABLE} \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
            --region ${REGION} | jq .
    fi

    export SSM_KEY="/k8s/${CLUSTER_ROLE}/${CLUSTER_NAME}"

    # AWS Systems Manager > 파라미터 스토어
    aws ssm put-parameter --name ${SSM_KEY}/admin_username --value "${ADMIN_USERNAME}" --type SecureString --overwrite | jq .
    aws ssm put-parameter --name ${SSM_KEY}/admin_password --value "${ADMIN_PASSWORD}" --type SecureString --overwrite | jq .

    aws ssm put-parameter --name ${SSM_KEY}/argocd_password --value "${ARGOCD_PASSWORD}" --type SecureString --overwrite | jq .
    aws ssm put-parameter --name ${SSM_KEY}/argocd_mtime --value "${ARGOCD_MTIME}" --type SecureString --overwrite | jq .

    aws ssm put-parameter --name ${SSM_KEY}/google_client_id --value "${GOOGLE_CLIENT_ID}" --type SecureString --overwrite | jq .
    aws ssm put-parameter --name ${SSM_KEY}/google_client_secret --value "${GOOGLE_CLIENT_SECRET}" --type SecureString --overwrite | jq .

    aws ssm put-parameter --name ${SSM_KEY}/github_client_id --value "${GITHUB_CLIENT_ID}" --type SecureString --overwrite | jq .
    aws ssm put-parameter --name ${SSM_KEY}/github_client_secret --value "${GITHUB_CLIENT_SECRET}" --type SecureString --overwrite | jq .

    aws ssm put-parameter --name ${SSM_KEY}/slack_token --value "${SLACK_TOKEN}" --type SecureString --overwrite | jq .

    aws ssm put-parameter --name ${SSM_KEY}/datadog_api_key --value "${DATADOG_API_KEY}" --type SecureString --overwrite | jq .
    aws ssm put-parameter --name ${SSM_KEY}/datadog_app_key --value "${DATADOG_APP_KEY}" --type SecureString --overwrite | jq .

    aws ssm put-parameter --name ${SSM_KEY}/logzio_token --value "${LOGZIO_TOKEN}" --type SecureString --overwrite | jq .
}

_main

_success
