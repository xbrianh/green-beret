# green-beret

This repo contains Terraform definitions and scripts to deploy personalized cloud instances to AWS and GCP, with the
following features:
  - Instance networks are configured to allow [mosh](https://mosh.org/) connections. Mosh is similar to ssh, but more
	robust against low bandwidth and intermittent connections.
  - Instances are tagged, see the env var `GREEN_BERET_INFRA_TAGS` in configuration files.
  - Configuration and personalization is relatively straightforward.
  - After initial setup, instance deploy and destroy is handled with `make`, and `make destroy`, respectively.

## Requirements

- [Mosh](https://mosh.org/)
- [Python 3.8](https://www.python.org/downloads/)
- [Terraform v0.13.0](https://www.terraform.io/downloads.html)
- [jq](https://stedolan.github.io/jq/download/)

You may also find it useful to install the AWS CLI and the gcloud suite:
  - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
  - [gcloud](https://cloud.google.com/sdk/install)

It's also possible to install the AWS CLI via pip with `pip install awscli`.

## Usage

### Initial Setup

1. Fork this repo (see "fork" button on upper right of GitHub page).
1. Create a bucket to store Terraform state. The bucket name should be personalized to your cloud account, and to you.
   There should be a bucket for each platform you intend to use: if you're deploying instances to both AWS and GCP, you
   will need two buckets.

   Using the AWS CLI
   ```
   aws s3 mb s3://terraform-{account_number}-{my-github-id}
   ```

   Using gsutil
   ```
   gsutil mb gs://terraform-{account_number}-{my-github-id}
   ```
1. Edit the contents of the `instance_config` directory to your taste.
1. Copy and edit either `environment.aws.example` or `environment.aws.example`. You can have both, and as many copies
   of either, as needed.

#### AWS Initial Setup
Create an AWS EC2 key pair (This only needs to be done once per AWS account):
```
scripts/create_aws_key_pair.py
```
Please pay attention to the env vars `GREEN_BERET_AWS_KEY_PAIR_NAME` and `GREEN_BERET_AWS_KEY_PAIR_SECRET_ID` before
you run this command.

#### GCP Initial Setup
Create a key pair and put it in a safe place on your computer. On Mac OS or linux,
```
ssh-keygen -t rsa
```

#### GCP Initial Setup

### Deploying, connection, and destroying

To create and connect to an instance
```
source environment.aws.my_instance
make
source environment.derived
scripts/login
```

Occasionally, for cloud reasons, the instance may not completely stand up. In this case, run `make reconfigure`.

To tear down an instance
```
make destroy
```

Note that instance teardown will remove _all_ instance infrastructure. All data on the instance hard drive will be
lost.
