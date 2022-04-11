#!/usr/bin/env bash

CMD=${1}

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

  aws s3 cp ./run.env s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/
  aws s3 cp ./system.env s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/

  aws s3 cp ./custom_files/hyperparameters.json s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/
  aws s3 cp ./custom_files/model_metadata.json s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/
  aws s3 cp ./custom_files/reward_function.py s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/

  popd
}

_restore() {
  pushd ~/deepracer-for-cloud

  CNT=$(aws s3 ls s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME} | wc -l | xargs)
  if [ "x${CNT}" != "x0" ]; then
    aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/run.env ./
    aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/system.env ./
  fi

  CNT=$(aws s3 ls s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files | wc -l | xargs)
  if [ "x${CNT}" != "x0" ]; then
    aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/hyperparameters.json ./custom_files/
    aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/model_metadata.json ./custom_files/
    aws s3 cp s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/custom_files/reward_function.py ./custom_files/
  fi

  popd
}

_init() {
  DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

  DR_WORLD_NAME=$(aws ssm get-parameter --name "/dr-cloud/world_name" --with-decryption | jq .Parameter.Value -r)

  # autorun.s3url
  aws s3 cp ~/run.sh s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/autorun.sh
  echo "${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}" >~/deepracer-for-cloud/autorun.s3url

  # git clone https://github.com/aws-deepracer-community/deepracer-for-cloud.git
  # pushd ~/deepracer-for-cloud
  # echo "s3://${DR_LOCAL_S3_BUCKET}/${DR_WORLD_NAME}/autorun.sh" >./autorun.s3url
  # ./bin/prepare.sh
  # popd
}

_main() {
  DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"

  DR_WORLD_NAME=$(aws ssm get-parameter --name "/dr-cloud/world_name" --with-decryption | jq .Parameter.Value -r)
  DR_MODEL_BASE=$(aws ssm get-parameter --name "/dr-cloud/model_base" --with-decryption | jq .Parameter.Value -r)

  _restore

  pushd ~/deepracer-for-cloud

  source ./bin/activate.sh

  RL_COACH=$(cat defaults/dependencies.json | jq .containers.rl_coach -r)
  SAGEMAKER=$(cat defaults/dependencies.json | jq .containers.sagemaker -r)
  ROBOMAKER=$(cat defaults/dependencies.json | jq .containers.robomaker -r)

  # run.env
  DR_CURRENT_MODEL_BASE=$(grep -e '^DR_MODEL_BASE=' run.env | cut -d'=' -f2)

  if [ "${DR_CURRENT_MODEL_BASE}" != "${DR_MODEL_BASE}" ]; then
    sed -i "s/\(^DR_LOCAL_S3_MODEL_PREFIX=\)\(.*\)/\1$DR_MODEL_BASE/" run.env
    sed -i "s/.*DR_LOCAL_S3_PRETRAINED.*/DR_LOCAL_S3_PRETRAINED=False/" run.env

    if [ "${DR_CURRENT_MODEL_BASE}" == "" ]; then
      echo "DR_MODEL_BASE=${DR_MODEL_BASE}" >>run.env
    else
      sed -i "s/\(^DR_MODEL_BASE=\)\(.*\)/\1$DR_MODEL_BASE/" run.env
    fi
  else
    _increment
  fi

  sed -i "s/\(^DR_WORLD_NAME=\)\(.*\)/\1$DR_WORLD_NAME/" run.env

  # system.env
  DR_AWS_APP_REGION="$(aws configure get default.region)"
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

  date | tee ./DONE-AUTORUN

  popd

  _backup

  _start

  # sleep 30

  # _viewer
  # _loganalysis
}

_start() {
  pushd ~/deepracer-for-cloud

  dr-update && dr-upload-custom-files && dr-start-training

  popd
}

_increment() {
  pushd ~/deepracer-for-cloud

  dr-increment-training -f

  popd
}

_viewer() {
  pushd ~/deepracer-for-cloud

  dr-stop-viewer && dr-start-viewer

  popd
}

_analysis() {
  pushd ~/deepracer-for-cloud

  dr-stop-loganalysis && dr-start-loganalysis

  popd
}

_upload() {
  pushd ~/deepracer-for-cloud

  dr-upload-model

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
s | start)
  _start
  ;;
v | viewer)
  _viewer
  ;;
a | analysis)
  _analysis
  ;;
u | upload)
  _upload
  ;;
*)
  _main
  ;;
esac
