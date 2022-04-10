# terraform-aws-deepracer-cloud

* <https://mungi.notion.site/DRfC-in-AWS-g4dn-2xlarge-c908e42f16324a6492f67d4d40b61f31>
* <https://github.com/aws-deepracer-community>

> 위 문서를 참고하여 만들었습니다.
> 이 테라폼을 실행 하면, 위 문서의 `init.sh 실행` 까지 실행 됩니다.

## replace

> 이 쉘을 실행하면, 테라폼 백엔드의 버켓을 aws account id 를 포함하는 문자로 변경하고, 버켓이 없다면 버켓을 생성 합니다.

```bash
./replace.sh

# ACCOUNT_ID = 123456789012
# REGION = us-west-2
# BUCKET = terraform-workshop-123456789012
```

## terraform apply

```bash
terraform apply

# ...

Outputs:

bucket_local = "aws-deepracer-123456789012-local"
bucket_upload = "aws-deepracer-123456789012-upload"
public_ip = "54.69.00.00"
```

## 인스턴스 생성 후 로그

> 생성 후 바로 접속하면, 초기화가 진행 중 입니다. 아래 명령어로 진행 상황을 알 수 있습니다.

```bast
tail -f -n 1000 /var/log/user-data.log
```

## 환경 변수 설정 및 실행

```bash
cd ~/deepracer-for-cloud

ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account -r)

RL_COACH=$(cat defaults/dependencies.json | jq .containers.rl_coach -r)
SAGEMAKER=$(cat defaults/dependencies.json | jq .containers.sagemaker -r)
ROBOMAKER=$(cat defaults/dependencies.json | jq .containers.robomaker -r)

# 훈련 환경 설정 : run.env
DR_WORLD_NAME="2022_april_pro"
DR_LOCAL_S3_MODEL_PREFIX="DR-2204-PRO-A-1"
DR_LOCAL_S3_PRETRAINED="False"

sed -i  "s/\(^DR_WORLD_NAME=\)\(.*\)/\1$DR_WORLD_NAME/" run.env
sed -i  "s/\(^DR_LOCAL_S3_MODEL_PREFIX=\)\(.*\)/\1$DR_LOCAL_S3_MODEL_PREFIX/" run.env
sed -i  "s/\(^DR_LOCAL_S3_PRETRAINED=\)\(.*\)/\1$DR_LOCAL_S3_PRETRAINED/" run.env

# 시스템 환경 설정 변경 : system.env
DR_AWS_APP_REGION="us-west-2"
DR_LOCAL_S3_PROFILE="default"
DR_UPLOAD_S3_PROFILE="default"
DR_LOCAL_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-local"
DR_UPLOAD_S3_BUCKET="aws-deepracer-${ACCOUNT_ID}-upload"
DR_DOCKER_STYLE="compose"
DR_SAGEMAKER_IMAGE="${SAGEMAKER}-gpu"
DR_ROBOMAKER_IMAGE="${ROBOMAKER}-gpu"   # 5.0.1-gpu-gl
DR_COACH_IMAGE="${RL_COACH}"
DR_WORKERS="6"                   # 동시 실행 Worker 개수, 대충 4vCPU당 RoboMaker 1개 정도 수행 가능 + Sagemaker 4vCPU
DR_GUI_ENABLE="False"            # 활성화시 Worker Gagebo에 VNC로 GUI 접속 가능, PW 없음 => CPU 추가 사용하며,볼일이 없으므로 비활성 권장
DR_KINESIS_STREAM_ENABLE="True"  # 활성화시 경기 합성 화면 제공 => CPU 추가 사용하지만, 보기편하므로 활성
DR_KINESIS_STREAM_NAME=""

sed -i "s/\(^DR_AWS_APP_REGION=\)\(.*\)/\1$DR_AWS_APP_REGION/"       system.env
sed -i "s/\(^DR_LOCAL_S3_PROFILE=\)\(.*\)/\1$DR_LOCAL_S3_PROFILE/"   system.env
sed -i "s/\(^DR_LOCAL_S3_BUCKET=\)\(.*\)/\1$DR_LOCAL_S3_BUCKET/"     system.env
sed -i "s/\(^DR_UPLOAD_S3_PROFILE=\)\(.*\)/\1$DR_UPLOAD_S3_PROFILE/" system.env
sed -i "s/\(^DR_UPLOAD_S3_BUCKET=\)\(.*\)/\1$DR_UPLOAD_S3_BUCKET/"   system.env
sed -i "s/\(^DR_DOCKER_STYLE=\)\(.*\)/\1$DR_DOCKER_STYLE/"           system.env
sed -i "s/\(^DR_SAGEMAKER_IMAGE=\)\(.*\)/\1$DR_SAGEMAKER_IMAGE/"     system.env
sed -i "s/\(^DR_ROBOMAKER_IMAGE=\)\(.*\)/\1$DR_ROBOMAKER_IMAGE/"     system.env
sed -i "s/\(^DR_COACH_IMAGE=\)\(.*\)/\1$DR_COACH_IMAGE/"             system.env
sed -i "s/\(^DR_WORKERS=\)\(.*\)/\1$DR_WORKERS/"                     system.env
sed -i "s/\(^DR_GUI_ENABLE=\)\(.*\)/\1$DR_GUI_ENABLE/"               system.env
sed -i "s/\(^DR_KINESIS_STREAM_ENABLE=\)\(.*\)/\1$DR_KINESIS_STREAM_ENABLE/" system.env
sed -i "s/\(^DR_KINESIS_STREAM_NAME=\)\(.*\)/\1$DR_KINESIS_STREAM_NAME/"     system.env

sed -i "s/.*CUDA_VISIBLE_DEVICES.*/CUDA_VISIBLE_DEVICES=0/" system.env

echo -e "\n" >> system.env

cat <<EOF >>system.env
DR_LOCAL_S3_PREFIX=drfc-1
DR_UPLOAD_S3_PREFIX=drfc-1
EOF

aws s3 ls | grep deepracer
```

## 실행

```bash
# 장시간이므로 터미널을 끊고 나와야 하므로 가능하면 tmux에서 실행하자.
# 끊어도 계속 실행이 되긴 하지만 로그등 터미널 레이아웃 유지를 위해 권장
tmux new -s deepracer

cd ~/deepracer-for-cloud

# 업데이트 및 훈련 시작
dr-update && dr-upload-custom-files && dr-start-training -w

# 증가 실행
dr-stop-training
dr-increment-training -f
dr-update && dr-upload-custom-files && dr-start-training -w

# tmux 화면을 3 등분 하고 나머지 하나에서 모니터링과 커맨드 수행
# 브라우저에서 8100 포트로 접속해보자 DR_KINESIS_STREAM_ENABLE가 True 일 때만 가능하다.
dr-stop-viewer && dr-start-viewer
```
