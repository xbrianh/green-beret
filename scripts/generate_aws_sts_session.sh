#!/bin/bash
# This is used to generate temporary credentials when using Terraform with MFA enabled
# See issue: https://github.com/terraform-providers/terraform-provider-aws/issues/2420
set -euo pipefail
if [[ 1 != $# ]]; then
    echo "Usage:"
    echo "$0 role-arn"
	exit 1
fi
role_arn=$1
role_json=$(aws sts assume-role --role-arn ${role_arn} --role-session-name teraform --duration-seconds 3600)
export AWS_ACCESS_KEY_ID="$(echo ${role_json} | jq -r '.Credentials.AccessKeyId')"
export AWS_SECRET_ACCESS_KEY="$(echo ${role_json} | jq -r '.Credentials.SecretAccessKey')"
export AWS_SESSION_TOKEN="$(echo ${role_json} | jq -r '.Credentials.SessionToken')"
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
