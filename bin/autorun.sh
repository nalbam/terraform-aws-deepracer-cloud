#!/usr/bin/env bash

AWS_RESION=$(aws configure get default.region)

ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account -r)

DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

DR_WORLD_NAME=$(aws ssm get-parameter --name "/dr-cloud/world_name" --with-decryption | jq .Parameter.Value -r)

INSTALL_DIR_TEMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

# activate
source $INSTALL_DIR_TEMP/bin/activate.sh

aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/run.env $INSTALL_DIR_TEMP/run.prev
aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/system.env $INSTALL_DIR_TEMP/system.prev

aws s3 sync s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/ $INSTALL_DIR_TEMP/custom_files/

DR_WORLD_NAME=$(aws ssm get-parameter --name "/dr-cloud/world_name" --with-decryption | jq .Parameter.Value -r)
DR_MODEL_BASE=$(aws ssm get-parameter --name "/dr-cloud/model_base" --with-decryption | jq .Parameter.Value -r)

# run.env
PREV_MODEL_BASE=$(grep -e '^DR_MODEL_BASE=' $INSTALL_DIR_TEMP/run.prev | cut -d'=' -f2)
PREV_MODEL_NAME=$(grep -e '^DR_LOCAL_S3_MODEL_PREFIX=' $INSTALL_DIR_TEMP/run.prev | cut -d'=' -f2)

if [ "${PREV_MODEL_BASE}" != "${DR_MODEL_BASE}" ]; then
  # new model
  echo "[${PREV_MODEL_BASE}] -> [${DR_MODEL_BASE}] new"

  sed -i "s/\(^DR_LOCAL_S3_MODEL_PREFIX=\)\(.*\)/\1$DR_MODEL_BASE/" $INSTALL_DIR_TEMP/run.env
else
  # clone model
  echo "[${PREV_MODEL_NAME}] clone"

  sed -i "s/\(^DR_LOCAL_S3_MODEL_PREFIX=\)\(.*\)/\1$PREV_MODEL_NAME/" $INSTALL_DIR_TEMP/run.env

  dr-increment-training -f
fi

sed -i "s/\(^DR_WORLD_NAME=\)\(.*\)/\1$DR_WORLD_NAME/" $INSTALL_DIR_TEMP/run.env

echo "" >>$INSTALL_DIR_TEMP/run.env
echo "DR_MODEL_BASE=${DR_MODEL_BASE}" >>$INSTALL_DIR_TEMP/run.env

# image version
RL_COACH=$(cat $INSTALL_DIR_TEMP/defaults/dependencies.json | jq .containers.rl_coach -r)
SAGEMAKER=$(cat $INSTALL_DIR_TEMP/defaults/dependencies.json | jq .containers.sagemaker -r)
ROBOMAKER=$(cat $INSTALL_DIR_TEMP/defaults/dependencies.json | jq .containers.robomaker -r)

# system.env
DR_AWS_APP_REGION="$(aws configure get default.region)"
DR_LOCAL_S3_PROFILE="default"
DR_UPLOAD_S3_PROFILE="default"
DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"
DR_UPLOAD_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-upload"
DR_DOCKER_STYLE="compose"
DR_SAGEMAKER_IMAGE="${SAGEMAKER}-gpu"
DR_ROBOMAKER_IMAGE="${ROBOMAKER}-cpu-avx2" # 5.0.1-gpu-gl
DR_COACH_IMAGE="${RL_COACH}"
DR_WORKERS="6"                  # 동시 실행 Worker 개수, 대충 4vCPU당 RoboMaker 1개 정도 수행 가능 + Sagemaker 4vCPU
DR_GUI_ENABLE="False"           # 활성화시 Worker Gagebo에 VNC로 GUI 접속 가능, PW 없음 => CPU 추가 사용하며,볼일이 없으므로 비활성 권장
DR_KINESIS_STREAM_ENABLE="True" # 활성화시 경기 합성 화면 제공 => CPU 추가 사용하지만, 보기편하므로 활성
DR_KINESIS_STREAM_NAME=""
CUDA_VISIBLE_DEVICES="0"

sed -i "s/\(^DR_AWS_APP_REGION=\)\(.*\)/\1$DR_AWS_APP_REGION/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_LOCAL_S3_PROFILE=\)\(.*\)/\1$DR_LOCAL_S3_PROFILE/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_LOCAL_S3_BUCKET=\)\(.*\)/\1$DR_LOCAL_S3_BUCKET/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_UPLOAD_S3_PROFILE=\)\(.*\)/\1$DR_UPLOAD_S3_PROFILE/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_UPLOAD_S3_BUCKET=\)\(.*\)/\1$DR_UPLOAD_S3_BUCKET/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_DOCKER_STYLE=\)\(.*\)/\1$DR_DOCKER_STYLE/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_SAGEMAKER_IMAGE=\)\(.*\)/\1$DR_SAGEMAKER_IMAGE/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_ROBOMAKER_IMAGE=\)\(.*\)/\1$DR_ROBOMAKER_IMAGE/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_COACH_IMAGE=\)\(.*\)/\1$DR_COACH_IMAGE/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_WORKERS=\)\(.*\)/\1$DR_WORKERS/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_GUI_ENABLE=\)\(.*\)/\1$DR_GUI_ENABLE/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_KINESIS_STREAM_ENABLE=\)\(.*\)/\1$DR_KINESIS_STREAM_ENABLE/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^DR_KINESIS_STREAM_NAME=\)\(.*\)/\1$DR_KINESIS_STREAM_NAME/" $INSTALL_DIR_TEMP/system.env
sed -i "s/\(^CUDA_VISIBLE_DEVICES=\)\(.*\)/\1$CUDA_VISIBLE_DEVICES/" $INSTALL_DIR_TEMP/system.env

echo "" >>$INSTALL_DIR_TEMP/system.env
echo "DR_LOCAL_S3_PREFIX=dr-cloud-1" >>$INSTALL_DIR_TEMP/system.env
echo "DR_UPLOAD_S3_PREFIX=dr-cloud-1" >>$INSTALL_DIR_TEMP/system.env

aws s3 cp $INSTALL_DIR_TEMP/run.env s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/
aws s3 cp $INSTALL_DIR_TEMP/system.env s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/

aws s3 sync $INSTALL_DIR_TEMP/custom_files/ s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/

dr-reload

date | tee $INSTALL_DIR_TEMP/DONE-AUTORUN

## start training
cd $INSTALL_DIR_TEMP/scripts/training
./start.sh -w -v
