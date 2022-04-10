#!/usr/bin/env bash

CMD=${1}

CNT=$(ps -ef | grep containerd-shim-runc | wc -l)

# if [ ! -f "./run.env" ] || [ ! -f "./system.env" ] || [ "$CNT" -gt "8" ]; then
#   exit 1
# fi

ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account -r)

_usage() {
  cat <<EOF
================================================================================
 Usage: $(basename $0) {init|backup|restore}
================================================================================
EOF
}

_backup() {
  pushd ~/deepracer-for-cloud

  DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

  aws s3 cp ./run.env s3://${DR_LOCAL_S3_BUCKET}/
  aws s3 cp ./system.env s3://${DR_LOCAL_S3_BUCKET}/

  popd
}

_restore() {
  pushd ~/deepracer-for-cloud

  DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

  aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/run.env ./
  aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/system.env ./

  aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/custom_files/hyperparameters.json ./custom_files/
  aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/custom_files/model_metadata.json ./custom_files/
  aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/custom_files/reward_function.py ./custom_files/

  popd
}

_init() {
  curl -fsSL -o ~/dr-daemon https://raw.githubusercontent.com/nalbam/terraform-aws-deepracer-cloud/main/bin/dr-daemon.sh
  curl -fsSL -o ~/dr-trainer https://raw.githubusercontent.com/nalbam/terraform-aws-deepracer-cloud/main/bin/dr-trainer.sh
  chmod 755 dr-daemon dr-trainer
  sudo cp dr-daemon /etc/init.d/dr-trainer
  sudo service dr-trainer start
  sudo update-rc.d dr-trainer defaults 99

  pushd ~/deepracer-for-cloud

  DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

  RL_COACH=$(cat defaults/dependencies.json | jq .containers.rl_coach -r)
  SAGEMAKER=$(cat defaults/dependencies.json | jq .containers.sagemaker -r)
  ROBOMAKER=$(cat defaults/dependencies.json | jq .containers.robomaker -r)

  # 훈련 환경 설정 : run.env
  DR_WORLD_NAME="2022_april_pro"
  DR_LOCAL_S3_MODEL_PREFIX="DR-2204-PRO-A-1"
  DR_LOCAL_S3_PRETRAINED="False"

  sed -i "s/\(^DR_WORLD_NAME=\)\(.*\)/\1$DR_WORLD_NAME/" run.env
  sed -i "s/\(^DR_LOCAL_S3_MODEL_PREFIX=\)\(.*\)/\1$DR_LOCAL_S3_MODEL_PREFIX/" run.env
  sed -i "s/\(^DR_LOCAL_S3_PRETRAINED=\)\(.*\)/\1$DR_LOCAL_S3_PRETRAINED/" run.env

  # 시스템 환경 설정 변경 : system.env
  DR_AWS_APP_REGION="us-west-2"
  DR_LOCAL_S3_PROFILE="default"
  DR_UPLOAD_S3_PROFILE="default"
  DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"
  DR_UPLOAD_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-upload"
  DR_DOCKER_STYLE="compose"
  DR_SAGEMAKER_IMAGE="${SAGEMAKER}-gpu"
  DR_ROBOMAKER_IMAGE="${ROBOMAKER}-gpu" # 5.0.1-gpu-gl
  DR_COACH_IMAGE="${RL_COACH}"
  DR_WORKERS="6"                  # 동시 실행 Worker 개수, 대충 4vCPU당 RoboMaker 1개 정도 수행 가능 + Sagemaker 4vCPU
  DR_GUI_ENABLE="False"           # 활성화시 Worker Gagebo에 VNC로 GUI 접속 가능, PW 없음 => CPU 추가 사용하며,볼일이 없으므로 비활성 권장
  DR_KINESIS_STREAM_ENABLE="True" # 활성화시 경기 합성 화면 제공 => CPU 추가 사용하지만, 보기편하므로 활성
  DR_KINESIS_STREAM_NAME=""

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

  sed -i "s/.*CUDA_VISIBLE_DEVICES.*/CUDA_VISIBLE_DEVICES=0/" system.env

  echo -e "\n" >>system.env

  cat <<EOF >>system.env
DR_LOCAL_S3_PREFIX=drfc-1
DR_UPLOAD_S3_PREFIX=drfc-1
EOF

  popd
}

case ${CMD} in
i | init)
  _init
  ;;
b | backup)
  _backup
  ;;
r | restore)
  _restore
  ;;
*)
  _usage
  ;;
esac
