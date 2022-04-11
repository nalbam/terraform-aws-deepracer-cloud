# terraform-aws-deepracer-cloud

* <https://github.com/aws-deepracer-community/deepracer-for-cloud>

## config

> Save the environment variable json in AWS SSM.

```bash
aws configure set default.region us-west-2
aws configure set default.output json

DR_WORLD_NAME="2022_april_pro"
DR_MODEL_BASE="DR-2204-PRO-A-1"

# put aws ssm parameter store
aws ssm put-parameter --name "/dr-cloud/world_name" --value "${DR_WORLD_NAME}" --type SecureString --overwrite | jq .
aws ssm put-parameter --name "/dr-cloud/model_base" --value "${DR_MODEL_BASE}" --type SecureString --overwrite | jq .

# get aws ssm parameter store
aws ssm get-parameter --name "/dr-cloud/world_name" --with-decryption | jq .Parameter.Value -r
aws ssm get-parameter --name "/dr-cloud/model_base" --with-decryption | jq .Parameter.Value -r
```

## replace

> Create bucket and dynamodb for Terraform backend.

```bash
./replace.sh

# ACCOUNT_ID = 123456789012
# REGION = ap-northeast-2
# BUCKET = terraform-workshop-123456789012
```

## terraform apply

> Create a Spot Instance with AutoscalingGroup.

```bash
terraform apply

# ...

Outputs:

bucket_local = "aws-deepracer-123456789012-local"
bucket_upload = "aws-deepracer-123456789012-upload"
public_ip = "54.69.00.00"
```

## custom_files

```bash
aws configure set default.region us-west-2
aws configure set default.output json

ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account -r)

DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

DR_WORLD_NAME="2022_april_pro"
DR_MODEL_BASE="DR-2204-PRO-B-1" # new model

aws ssm put-parameter --name "/dr-cloud/world_name" --value "${DR_WORLD_NAME}" --type SecureString --overwrite | jq .
aws ssm put-parameter --name "/dr-cloud/model_base" --value "${DR_MODEL_BASE}" --type SecureString --overwrite | jq .

aws s3 cp ./custom_files/hyperparameters.json s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/
aws s3 cp ./custom_files/model_metadata.json s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/
aws s3 cp ./custom_files/reward_function.py s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/
```
