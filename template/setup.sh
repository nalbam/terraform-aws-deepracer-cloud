#!/usr/bin/env bash

# Log everything we do.
set -x
exec > /var/log/user-data.log 2>&1

cat <<EOF > /etc/motd
#########################################################

#  아직 초기화가 진행중입니다.
#  완료하면 재부팅이 될 것입니다.

tail -f -n 1000 /var/log/user-data.log

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

apt-get install -y git vim tmux nmon

curl -fsSL -o /etc/init.d/autostart.sh https://raw.githubusercontent.com/nalbam/terraform-aws-deepracer-local/main/template/autostart.sh
chmod 755 /etc/init.d/autostart.sh
update-rc.d autostart.sh defaults

runuser -l ubuntu -c "curl -fsSL -o ~/run.sh https://raw.githubusercontent.com/nalbam/terraform-aws-deepracer-local/main/template/run.sh"
runuser -l ubuntu -c "chmod 755 ~/run.sh"

runuser -l ubuntu -c "cd ~ && git clone https://github.com/aws-deepracer-community/deepracer-for-cloud.git"
runuser -l ubuntu -c "cd ~/deepracer-for-cloud && ./bin/prepare.sh"

runuser -l ubuntu -c "sudo reboot now"
