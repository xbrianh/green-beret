# This is used to generate temporary credentials when using Terraform with MFA enabled
# See issue: https://github.com/terraform-providers/terraform-provider-aws/issues/2420
# Usage: `source generate_aws_sts_session.sh`
role_arn=${AWS_ROLE_ARN}
role_json=$(aws sts assume-role --role-arn ${role_arn} --role-session-name ${AWS_ROLE_SESSION_NAME} --duration-seconds 3600)
export AWS_ACCESS_KEY_ID="$(echo ${role_json} | jq -r '.Credentials.AccessKeyId')"
export AWS_SECRET_ACCESS_KEY="$(echo ${role_json} | jq -r '.Credentials.SecretAccessKey')"
export AWS_SESSION_TOKEN="$(echo ${role_json} | jq -r '.Credentials.SessionToken')"
