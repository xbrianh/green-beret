source environment
set -a
GREEN_BERET_PLATFORM="aws"
AWS_DEFAULT_REGION="us-west-2"
GREEN_BERET_INSTANCE_NAME="green-beret"
TERRAFORM_STATE_BUCKET="terraform-422448306679-${AWS_DEFAULT_REGION}"
TERRAFORM_STATE_PREFIX="green-beret"
GREEN_BERET_AWS_KEY_PAIR_NAME="bhannafi-green-beret"
GREEN_BERET_AWS_KEY_PAIR_SECRET_ID="hpp/bhannafi/green-beret/aws-private-key"
GREEN_BERET_AWS_INSTANCE_TYPE="m5.large"
GREEN_BERET_INFRA_TAGS='{"service": "green-beret", "Owner": "bhannafi@ucsc.edu"}'
set +a
