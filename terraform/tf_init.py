#!/usr/bin/env python
"""
Build the Terraform deployment configuration files using environment variable values.
Requires a Google service account (but only to get the GCP project ID).
"""
import os
import glob
import json
import argparse

platform = os.environ['GREEN_BERET_PLATFORM']
if platform not in ["aws", "gcp"]:
    raise ValueError(f"Cannot generate backend.tf for unknown platform {platform}") 

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("path")
args = parser.parse_args()
path = os.path.abspath(args.path)
component = os.path.basename(path)

terraform_variable_template = """
    variable "{name}" {{
      default = "{val}"
    }}
""".replace("    ", "").strip()

terraform_s3_backend_template = """
# Auto-generated during terraform build process.
# Please edit terraform/build_deploy_config.py directly.
terraform {{
  backend "s3" {{
    bucket = "{bucket}"
    key = "{key}"
    region = "{region}"
    {profile_setting}
  }}
}}
""".strip()

terraform_gs_backend_template = """
# Auto-generated during terraform build process.
# Please edit terraform/build_deploy_config.py directly.
terraform {{
  backend "gcs" {{
    bucket = "{bucket}"
    prefix = "{prefix}"
  }}
}}
""".strip()

if "aws" == platform:
    terraform_providers = f"""
        # Auto-generated during terraform build process.
        # Please edit terraform/build_deploy_config.py directly.
        provider aws {{
          region = "{os.environ['AWS_DEFAULT_REGION']}"
        }}
    """.replace("    ", "").strip()
elif "gcp" == platform:
    from google.cloud.storage import Client
    gcp_project_id = Client().project
    terraform_providers = f"""
        # Auto-generated during terraform build process.
        # Please edit terraform/build_deploy_config.py directly.
        provider google {{
          project = "{gcp_project_id}"
        }}
    """.replace("    ", "").strip()
else:
    pass

with open(os.path.join(path, "backend.tf"), "w") as fp:
    if "aws" == platform:
        if os.environ.get('AWS_PROFILE'):
            profile = os.environ['AWS_PROFILE']
            profile_setting = f'profile = "{profile}"'
        else:
            profile_setting = ""
        region = os.environ['AWS_DEFAULT_REGION']
        backend_data = terraform_s3_backend_template.format(
            region=region,
            bucket=os.environ['TERRAFORM_STATE_BUCKET'],
            key="{os.environ['TERRAFORM_STATE_PREFIX']}/{comp}.tfstate",
            profile_setting=profile_setting,
        )
    elif "gcp" == platform:
        profile_setting = ""
        region = os.environ['GCP_DEFAULT_REGION']
        backend_data = terraform_gs_backend_template.format(
            bucket=os.environ['TERRAFORM_STATE_BUCKET'],
            prefix=f"{os.environ['TERRAFORM_STATE_PREFIX']}/{component}",
        )
    else:
        pass
    fp.write(backend_data)

with open(os.path.join(path, "variables.tf"), "w") as fp:
    fp.write("# Auto-generated during terraform build process." + os.linesep)
    fp.write("# Please edit terraform/build_deploy_config.py directly." + os.linesep)
    for key in os.environ['EXPORT_ENV_VARS_TO_TERRAFORM'].split():
        val = os.environ[key].replace('"', '\\"')
        fp.write(terraform_variable_template.format(name=key, val=val))
        fp.write(os.linesep)

with open(os.path.join(path, "providers.tf"), "w") as fp:
    fp.write(terraform_providers)
