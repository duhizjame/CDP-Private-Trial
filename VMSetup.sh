#!/bin/bash
echo "> Installing required tools for CDP TRIAL"
if  [ -n "$(command -v yum)" ]; then
    echo ">> Detected yum-based Linux"
    sudo yum install -y util-linux
    sudo yum install -y lvm2
    sudo yum install -y e2fsprogs
    sudo yum install -y git
    sudo yum install -y net-tools
    sudo curl -O https://bootstrap.pypa.io/pip/2.7/get-pip.py
    sudo python get-pip.py
    sudo pip install --upgrade pip cm_client
    sudo curl http://yum.mariadb.org/10.1/centos7-amd64/rpms/MariaDB-10.1.30-centos7-x86_64-shared.rpm
    sudo yum installlocal MariaDB-10.1.30-centos7-x86_64-shared.rpm
fi
if [ -n "$(command -v apt-get)" ]; then
    echo ">> Detected apt-based Linux"
    sudo apt-get update -y
    sudo apt-get install -y fdisk
    sudo apt-get install -y lvm2
    sudo apt-get install -y e2fsprogs
    sudo apt-get install -y git
fi
ROOT_DISK_DEVICE="/dev/sda"
echo "> Creating new partition for CDP"
sudo fdisk $ROOT_DISK_DEVICE <<EOF
d
n
p
1


w
EOF
sudo partprobe /dev/sda
sudo kpartx -u /dev/sda1
sudo e2fsck -f /dev/sda1
#sudo pvcreate /dev/sda1
sudo xfs_growfs /
cd /
sudo mkdir data

echo "Downloading CDP DC Trial Pre Req Install"

cd ~
git clone https://github.com/carrossoni/CDPDCTrial.git
sudo su
chmod -R  777 CDPDCTrial
cd CDPDCTrial
chmod 777 centosvmCDP.sh
sudo ./centosvmCDP.sh

sudo reboot

exit 0
