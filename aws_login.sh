#/bin/bash

tmpfile=/Users/Sairam/.aws/credentials

#aws sts assume-role --duration-seconds 28800 --role-arn "arn:aws:iam::070596614028:role/terraform-role" --role-session-name `whoami`-`date +%d%m%y`-session > $tmpfile

AWS_ACCESS_KEY_ID=`cat $tmpfile|jq -c '.Credentials.AccessKeyId'|tr -d '"'`
AWS_SECRET_ACCESS_KEY=`cat $tmpfile |jq -c '.Credentials.SecretAccessKey'|tr -d '"'`
AWS_SESSION_TOKEN=`cat $tmpfile|jq -c '.Credentials.SessionToken'|tr -d '"'`

#rm -rf $tmpfile

# aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile assumed-role
# aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile assumed-role
# aws configure set aws_session_token $AWS_SESSION_TOKEN --profile assumed-role
# aws configure set region us-east-1 --profile assumed-role

export AWS_DEFAULT_PROFILE=adfs
export AWS_PROFILE=adfs

echo "Role Assumption has completed successfully"

aws sts get-caller-identity