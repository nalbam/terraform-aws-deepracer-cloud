#!/usr/bin/env bash

# Log everything we do.
set -x
exec > /var/log/user-data.log 2>&1

hostname "${HOSTNAME}"

rm -rf /etc/motd
cat <<EOF > /etc/motd

#########################################################
#                                                       #
#   모든 로그는 원격지 로그 서버에 저장되고 있습니다.   #
#   비인가자의 경우 접속을 해지하여 주시기 바랍니다.    #
#                                                       #
#########################################################

>> ${HOSTNAME} <<

EOF

# runuser -l ec2-user -c "curl -sL opspresso.github.io/toaster/install.sh | bash"
# runuser -l ec2-user -c "curl -sL opspresso.github.io/tools/install.sh | bash"

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

wget https://raw.githubusercontent.com/nalbam/terraform-aws-deepracer-local/main/template/run.sh
chmod 755 run.sh && cp run.sh /etc/init.d/autostart.sh
update-rc.d autostart.sh defaults

runuser -l ubuntu -c "cd ~ && git clone https://github.com/aws-deepracer-community/deepracer-for-cloud.git"
runuser -l ubuntu -c "cd ~/deepracer-for-cloud && ./bin/prepare.sh"

runuser -l ubuntu -c "sudo reboot now"
