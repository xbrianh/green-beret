#!/usr/bin/env python
"""
Build the Terraform deployment configuration files using environment variable values.
Requires a Google service account (but only to get the GCP project ID).
"""
import os
import glob
import json
import boto3
import argparse

terraform_root = os.path.abspath(os.path.dirname(__file__))


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("path")
args = parser.parse_args()

path = os.path.abspath(args.path)
component = os.path.basename(path)


terraform_variable_template = """
variable "{name}" {{
  default = "{val}"
}}
"""

terraform_backend_template = """
# Auto-generated during terraform build process.
# Please edit terraform/build_deploy_config.py directly.
terraform {{
  backend "s3" {{
    bucket = "{bucket}"
    key = "{service}/{comp}.tfstate"
    region = "{region}"
    {profile_setting}
  }}
}}
""".strip()

terraform_providers = f"""
# Auto-generated during terraform build process.
# Please edit terraform/build_deploy_config.py directly.
provider aws {{
  region = "{os.environ['AWS_DEFAULT_REGION']}"
}}
""".strip()

with open(os.path.join(path, "backend.tf"), "w") as fp:
    caller_info = boto3.client("sts").get_caller_identity()
    if os.environ.get('AWS_PROFILE'):
        profile = os.environ['AWS_PROFILE']
        profile_setting = f'profile = "{profile}"'
    else:
        profile_setting = ''
    state_bucket = f"terraform-{caller_info['Account']}-{os.environ['AWS_DEFAULT_REGION']}"
    fp.write(terraform_backend_template.format(
        bucket=state_bucket,
        service=os.environ['AI_SERVICE'],
        comp=component,
        region=os.environ['AWS_DEFAULT_REGION'],
        profile_setting=profile_setting,
    ))

with open(os.path.join(path, "variables.tf"), "w") as fp:
    fp.write("# Auto-generated during terraform build process." + os.linesep)
    fp.write("# Please edit terraform/build_deploy_config.py directly." + os.linesep)
    for key in os.environ['EXPORT_ENV_VARS_TO_TERRAFORM'].split():
        val = os.environ[key]
        fp.write(terraform_variable_template.format(name=key, val=val))

with open(os.path.join(path, "providers.tf"), "w") as fp:
    fp.write(terraform_providers)
