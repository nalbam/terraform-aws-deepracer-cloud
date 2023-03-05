# terraform-aws-deepracer-cloud

* <https://github.com/aws-deepracer-community/deepracer-for-cloud>

## clone

```bash
git clone https://github.com/nalbam/terraform-aws-deepracer-cloud
```

## config

> Save the environment variable json in AWS SSM.

```bash
aws configure set default.region us-west-2
aws configure set default.output json

export DR_WORLD_NAME="2022_reinvent_champ"
export DR_MODEL_BASE="DR-22-CHAMP-A-1"

# put aws ssm parameter store
aws ssm put-parameter --name "/dr-cloud/world_name" --value "${DR_WORLD_NAME}" --type SecureString --overwrite | jq .
aws ssm put-parameter --name "/dr-cloud/model_base" --value "${DR_MODEL_BASE}" --type SecureString --overwrite | jq .

# # get aws ssm parameter store
# aws ssm get-parameter --name "/dr-cloud/world_name" --with-decryption | jq .Parameter.Value -r
# aws ssm get-parameter --name "/dr-cloud/model_base" --with-decryption | jq .Parameter.Value -r
```

## replace

> Create bucket and dynamodb for Terraform backend.

```bash
./replace.sh

# ACCOUNT_ID = 123456789012
# REGION = us-west-2
# BUCKET = terraform-workshop-123456789012
```

## terraform apply

> Create a Spot Instance with AutoscalingGroup.

```bash
# start
terraform apply

# ...

Outputs:

bucket_local = "aws-deepracer-123456789012-local"
bucket_upload = "aws-deepracer-123456789012-upload"
public_ip = "54.69.00.00"

# stop
terraform apply -var desired=0
```

## new model

```bash
aws configure set default.region us-west-2
aws configure set default.output json

export ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account -r)

export DR_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

export DR_WORLD_NAME="2022_reinvent_champ"
export DR_MODEL_BASE="DR-22-CHAMP-B-1" # new model

aws ssm put-parameter --name "/dr-cloud/world_name" --value "${DR_WORLD_NAME}" --type SecureString --overwrite | jq .
aws ssm put-parameter --name "/dr-cloud/model_base" --value "${DR_MODEL_BASE}" --type SecureString --overwrite | jq .

aws s3 sync --exact-timestamps ./${DR_WORLD_NAME}/ s3://${DR_S3_BUCKET}/${DR_WORLD_NAME}/
```
