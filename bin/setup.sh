#!/usr/bin/env bash

# Log everything we do.
set -x
exec >/var/log/user-data.log 2>&1

cat <<EOF | tee -a /etc/motd
#########################################################

# deepracer-local

tail -f -n 1000 /var/log/user-data.log

dr-start-training -w -v

dr-increment-training -f

dr-upload-model -f -b

#########################################################
EOF

sgdisk --zap-all /dev/nvme1n1
parted -s /dev/nvme1n1 mklabel gpt
parted -s /dev/nvme1n1 mkpart primary 1MiB 1025MiB
parted -s /dev/nvme1n1 align-check optimal 1
parted -s /dev/nvme1n1 resizepart 1 100%
mkfs.xfs /dev/nvme1n1p1 -f -L Data-Disk

mkdir -p /data

cat <<EOF | tee -a /etc/fstab
LABEL=Data-Disk    /data    xfs    defaults,nofail  1  0
EOF

chown -R ubuntu:ubuntu /data
mount -a

mkdir -p /data/docker_dir
cat /etc/docker/daemon.json | jq --arg graph /data/docker_dir '. + {graph: $graph}' | tee /etc/docker/daemon.json
systemctl restart docker
lsblk

apt-get update && apt-get install -y git vim tmux nmon

apt-get install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa -y
apt-get install -y python3.9

rm -rf /usr/bin/python3 && ln -s /usr/bin/python3.9 /usr/bin/python3
rm -rf /usr/bin/python3-config && ln -s /usr/bin/python3.9-config /usr/bin/python3-config
python3 --version

curl -o "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip awscliv2.zip
./aws/install

runuser -l ubuntu -c "aws configure set default.region ${region}"
runuser -l ubuntu -c "aws configure set default.output json"

runuser -l ubuntu -c "curl -fsSL -o ~/run.sh https://raw.githubusercontent.com/nalbam/terraform-aws-deepracer-cloud/main/bin/run.sh"
runuser -l ubuntu -c "bash ~/run.sh init"
