#!/usr/bin/env bash

CMD=${1}

AWS_RESION=$(aws configure get default.region)

ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account -r)

DR_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

DR_WORLD_NAME=$(aws ssm get-parameter --name "/dr-cloud/world_name" --with-decryption | jq .Parameter.Value -r)

echo "AWS_RESION: ${AWS_RESION}"
echo "ACCOUNT_ID: ${ACCOUNT_ID}"
echo "DR_S3_BUCKET: ${DR_S3_BUCKET}"

_usage() {
  cat <<EOF
================================================================================
 Usage: $(basename $0) {init|backup|restore}
================================================================================
EOF
}

_status() {
  UPTIME=$(uptime)
  PUBLIC_IP=$(curl -sL icanhazip.com)
  SAGEMAKER=$(docker ps | grep sagemaker | wc -l | xargs)
  ROBOMAKER=$(docker ps | grep robomaker | wc -l | xargs)

  SLACK_TOKEN=$(aws ssm get-parameter --name "/dr-cloud/slack_token" --with-decryption | jq .Parameter.Value -r)

  if [ ! -z ${SLACK_TOKEN} ]; then
    # send slack
    curl -sL opspresso.github.io/tools/slack.sh | bash -s -- \
      --token="${SLACK_TOKEN}" --username="dr-cloud" \
      --color="good" --title="${PUBLIC_IP}" \
      "${UPTIME}\n sagemaker=\`${SAGEMAKER}\` robomaker=\`${ROBOMAKER}\`"
  fi
}

_init() {
  _status

  git clone https://github.com/aws-deepracer-community/deepracer-for-cloud.git

  # autorun.s3url
  aws s3 cp ~/run.sh s3://${DR_S3_BUCKET}/${DR_WORLD_NAME}/autorun.sh
  echo "${DR_S3_BUCKET}/${DR_WORLD_NAME}" >~/deepracer-for-cloud/autorun.s3url

  cd ~/deepracer-for-cloud
  ./bin/prepare.sh
}

_autorun() {
  cd ~/deepracer-for-cloud

  source ./bin/activate.sh

  DR_WORLD_NAME=$(aws ssm get-parameter --name "/dr-cloud/world_name" --with-decryption | jq .Parameter.Value -r)
  DR_MODEL_BASE=$(aws ssm get-parameter --name "/dr-cloud/model_base" --with-decryption | jq .Parameter.Value -r)

  echo "DR_WORLD_NAME: ${DR_WORLD_NAME}"
  echo "DR_MODEL_BASE: ${DR_MODEL_BASE}"

  # download
  aws s3 sync s3://${DR_S3_BUCKET}/${DR_WORLD_NAME}/ ./custom_files/

  # run.env
  PREV_MODEL_BASE=$(grep -e '^DR_MODEL_BASE=' ./custom_files/run.env | cut -d'=' -f2 | head -n 1)
  PREV_MODEL_NAME=$(grep -e '^DR_LOCAL_S3_MODEL_PREFIX=' ./custom_files/run.env | cut -d'=' -f2 | head -n 1)

  if [ "${PREV_MODEL_BASE}" != "${DR_MODEL_BASE}" ]; then
    # new model
    echo "[${PREV_MODEL_BASE}] -> [${DR_MODEL_BASE}] new"

    sed -i "s/\(^DR_LOCAL_S3_MODEL_PREFIX=\)\(.*\)/\1$DR_MODEL_BASE/" run.env
  else
    # clone model
    echo "[${PREV_MODEL_NAME}] clone"

    sed -i "s/\(^DR_LOCAL_S3_MODEL_PREFIX=\)\(.*\)/\1$PREV_MODEL_NAME/" run.env

    dr-increment-training -f
  fi

  sed -i "s/\(^DR_WORLD_NAME=\)\(.*\)/\1$DR_WORLD_NAME/" run.env

  CUR_MODEL_BASE=$(grep -e '^DR_MODEL_BASE=' ./run.env | cut -d'=' -f2 | head -n 1)
  if [ -z ${CUR_MODEL_BASE} ]; then
    echo "" >>run.env
    echo "DR_MODEL_BASE=${DR_MODEL_BASE}" >>run.env
  else
    sed -i "s/\(^DR_MODEL_BASE=\)\(.*\)/\1$DR_MODEL_BASE/" run.env
  fi

  # image version
  RL_COACH=$(cat defaults/dependencies.json | jq .containers.rl_coach -r)
  SAGEMAKER=$(cat defaults/dependencies.json | jq .containers.sagemaker -r)
  ROBOMAKER=$(cat defaults/dependencies.json | jq .containers.robomaker -r)

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

  sed -i "s/\(^DR_AWS_APP_REGION=\)\(.*\)/\1$DR_AWS_APP_REGION/" system.env
  sed -i "s/\(^DR_LOCAL_S3_PROFILE=\)\(.*\)/\1$DR_LOCAL_S3_PROFILE/" system.env
  sed -i "s/\(^DR_LOCAL_S3_BUCKET=\)\(.*\)/\1$DR_LOCAL_S3_BUCKET/" system.env
  sed -i "s/\(^DR_UPLOAD_S3_PROFILE=\)\(.*\)/\1$DR_UPLOAD_S3_PROFILE/" system.env
  sed -i "s/\(^DR_UPLOAD_S3_BUCKET=\)\(.*\)/\1$DR_UPLOAD_S3_BUCKET/" system.env
  sed -i "s/\(^DR_DOCKER_STYLE=\)\(.*\)/\1$DR_DOCKER_STYLE/" system.env
  sed -i "s/\(^DR_SAGEMAKER_IMAGE=\)\(.*\)/\1$DR_SAGEMAKER_IMAGE/" system.env
  sed -i "s/\(^DR_ROBOMAKER_IMAGE=\)\(.*\)/\1$DR_ROBOMAKER_IMAGE/" system.env
  sed -i "s/\(^DR_COACH_IMAGE=\)\(.*\)/\1$DR_COACH_IMAGE/" system.env
  sed -i "s/\(^DR_WORKERS=\)\(.*\)/\1$DR_WORKERS/" system.env
  sed -i "s/\(^DR_GUI_ENABLE=\)\(.*\)/\1$DR_GUI_ENABLE/" system.env
  sed -i "s/\(^DR_KINESIS_STREAM_ENABLE=\)\(.*\)/\1$DR_KINESIS_STREAM_ENABLE/" system.env
  sed -i "s/\(^DR_KINESIS_STREAM_NAME=\)\(.*\)/\1$DR_KINESIS_STREAM_NAME/" system.env
  sed -i "s/\(^CUDA_VISIBLE_DEVICES=\)\(.*\)/\1$CUDA_VISIBLE_DEVICES/" system.env

  # upload
  cp -rf ./run.env ./custom_files/
  cp -rf ./system.env ./custom_files/
  aws s3 sync ./custom_files/ s3://${DR_S3_BUCKET}/${DR_WORLD_NAME}/

  # status
  crontab -l >/tmp/crontab.sh
  CNT=$(cat /tmp/crontab.sh | grep 'run.sh status' | wc -l | xargs)
  if [ "x${CNT}" == "x0" ]; then
    # echo "@reboot /home/ubuntu/.runonce.sh___init_sh__c_aws__a_gpu" > /tmp/crontab.sh
    echo "" >>/tmp/crontab.sh
    echo "0 * * * * bash /home/ubuntu/run.sh status" >>/tmp/crontab.sh
    crontab /tmp/crontab.sh
  fi
  _status

  # done
  date | tee ./DONE-AUTORUN

  # start
  dr-reload
  dr-stop-training
  dr-start-training -w -v
}

case ${CMD} in
i | init)
  _init
  ;;
s | status)
  _status
  ;;
*)
  _autorun
  ;;
esac
