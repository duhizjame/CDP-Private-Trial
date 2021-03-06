#! /bin/bash
echo "-- Configure user cloudera with passwordless"
useradd cloudera -d /home/cloudera -p cloudera
usermod -aG wheel cloudera
cp /etc/sudoers /etc/sudoers.bkp
rm -rf /etc/sudoers
sed '/^#includedir.*/a cloudera ALL=(ALL) NOPASSWD: ALL' /etc/sudoers.bkp > /etc/sudoers
echo "-- Configure and optimize the OS"
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
# add tuned optimization https://www.cloudera.com/documentation/enterprise/6/6.2/topics/cdh_admin_performance.html
echo  "vm.swappiness = 1" >> /etc/sysctl.conf
sysctl vm.swappiness=1
timedatectl set-timezone UTC
echo "no response from systemd??"

echo "-- Install Java OpenJDK8 and other tools"
# apt-get install -y java-1.8.0-openjdk-devel vim wget curl
# apt-get install -y python-pip

# cp /usr/lib/systemd/system/rngd.service /etc/systemd/system/
# systemctl daemon-reload
# systemctl start rngd
# systemctl enable rngd

echo "-- Installing requirements for Stream Messaging Manager"
apt-get install -y gcc-c++ make
curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash -
apt-get install nodejs -y
npm install forever -g

# echo "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4" >> /etc/chrony.conf
# systemctl restart chronyd

/etc/init.d/network restart

echo "-- Configure networking"
PUBLIC_IP=`curl https://api.ipify.org/`
#hostnamectl set-hostname `hostname -f`
# sed -i$(date +%s).bak '/^[^#]*cloudera/s/^/# /' /etc/hosts
# sed -i$(date +%s).bak '/^[^#]*::1/s/^/# /' /etc/hosts
echo "`host cloudera | grep address | awk '{print $4}'` `hostname` `hostname`" >> /etc/hosts
# #sed -i "s/HOSTNAME=.*/HOSTNAME=`hostname`/" /etc/sysconfig/network
systemctl disable ufw
systemctl stop ufw
service ufw stop
setenforce 0
# sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
# systemctl start ntpd
# systemctl restart network

echo  "Disabling IPv6"
echo "net.ipv6.conf.all.disable_ipv6 = 1
      net.ipv6.conf.default.disable_ipv6 = 1
      net.ipv6.conf.lo.disable_ipv6 = 1
      net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

echo "-- Install CM and MariaDB"

# CM 7
cd /
# wget https://archive.cloudera.com/cm7/7.4.4/redhat7/apt-get/cloudera-manager-trial.repo -P /etc/apt-get.repos.d/
RUN add-apt-repository "deb [arch=amd64] http://archive.cloudera.com/cm7/7.4.4/ubuntu1804/apt bionic-cm7.4.4 contrib"
# MariaDB 10.1
# cat - >/etc/apt-get.repos.d/MariaDB.repo <<EOF
# [mariadb]
# name = MariaDB
# baseurl = http://apt-get.mariadb.org/10.1/centos7-amd64
# gpgkey=https://apt-get.mariadb.org/RPM-GPG-KEY-MariaDB
# gpgcheck=1
# EOF
apt-get install -y mariadb-server mariadb-client


## CM
apt-get install -y cloudera-manager-agent cloudera-manager-daemons cloudera-manager-server

## THESE COMMANDS DO NOT WORK AS INTENDED

# sed -i$(date +%s).bak '/^[^#]*server_host/s/^/# /' /etc/cloudera-scm-agent/config.ini
# sed -i$(date +%s).bak '/^[^#]*listening_ip/s/^/# /' /etc/cloudera-scm-agent/config.ini
# sed -i$(date +%s).bak "/^# server_host.*/i server_host=$(hostname)" /etc/cloudera-scm-agent/config.ini
# sed -i$(date +%s).bak "/^# listening_ip=.*/i listening_ip=172.17.0.2" /etc/cloudera-scm-agent/config.ini
sed -i '' -e 's/server_host=.*/server_host=cloudera/' /etc/cloudera-scm-agent/config.ini
sed -i '' -e 's/# listening_ip=.*/listening_ip=172.17.0.2/' /etc/cloudera-scm-agent/config.ini

service cloudera-scm-agent restart

## MariaDB
apt-get install -y MariaDB-server MariaDB-client
cat conf/mariadb.config > /etc/my.cnf

echo "--Enable and start MariaDB"
systemctl enable mariadb
systemctl start mariadb

echo "-- Install JDBC connector"
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz -P ~
tar zxf ~/mysql-connector-java-5.1.46.tar.gz -C ~
mkdir -p /usr/share/java/
cp ~/mysql-connector-java-5.1.46/mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar
rm -rf ~/mysql-connector-java-5.1.46*


echo "-- Create DBs required by CM"
cd /home/cloudera/CDP-Private-Trial/CDPDCTrial
mysql -u root < scripts/create_db.sql

echo "-- Secure MariaDB"
mysql -u root < scripts/secure_mariadb.sql

echo "-- Prepare CM database 'scm'"
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm cloudera

## PostgreSQL
#apt-get install -y postgresql-server python-pip
#pip install psycopg2==2.7.5 --ignore-installed
#echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
#sudo su -l postgres -c "postgresql-setup initdb"
#cat conf/pg_hba.conf > /var/lib/pgsql/data/pg_hba.conf
#cat conf/postgresql.conf > /var/lib/pgsql/data/postgresql.conf
#echo "--Enable and start pgsql"
#systemctl enable postgresql
#systemctl restart postgresql


## PostgreSQL see: https://www.postgresql.org/download/linux/redhat/
apt-get install -y https://download.postgresql.org/pub/repos/apt-get/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
apt-get install -y postgresql-9.6
apt-get install -y postgresql-client-9.6
pip install psycopg2==2.7.5 --ignore-installed

echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
/usr/pgsql-9.6/bin/postgresql96-setup initdb

cat /home/cloudera/CDP-Private-Trial/CDPDCTrial/conf/pg_hba.conf > /var/lib/pgsql/9.6/data/pg_hba.conf
cat /home/cloudera/CDP-Private-Trial/CDPDCTrial/conf/postgresql.conf > /var/lib/pgsql/9.6/data/postgresql.conf

echo "--Enable and start pgsql"
systemctl enable postgresql-9.6
systemctl start postgresql-9.6

echo "-- Create DBs required by CM"
sudo -u postgres psql <<EOF 
CREATE DATABASE ranger;
CREATE USER ranger WITH PASSWORD 'cloudera';
GRANT ALL PRIVILEGES ON DATABASE ranger TO ranger;
CREATE DATABASE das;
CREATE USER das WITH PASSWORD 'cloudera';
GRANT ALL PRIVILEGES ON DATABASE das TO das;
EOF

echo "-- Install CSDs"

# # install local CSDs
# mv ~/*.jar /opt/cloudera/csd/
# mv /home/centos/*.jar /opt/cloudera/csd/
# chown cloudera-scm:cloudera-scm /opt/cloudera/csd/*
# chmod 644 /opt/cloudera/csd/*

# echo "-- Install local parcels"
# mv ~/*.parcel ~/*.parcel.sha /opt/cloudera/parcel-repo/
# mv /home/centos/*.parcel /home/centos/*.parcel.sha /opt/cloudera/parcel-repo/
# chown cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/*


echo "-- Enable password/passwordless root login via rsa key"
ssh-keygen -f ~/myRSAkey -t rsa -N ""
mkdir ~/.ssh
cat ~/myRSAkey.pub >> ~/.ssh/authorized_keys
chmod 400 ~/.ssh/authorized_keys
ssh-keyscan -H `hostname` >> ~/.ssh/known_hosts
sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# echo "-- Start CM, it takes about 2 minutes to be ready"
# systemctl start cloudera-scm-server

# while [ `curl -s -X GET -u "admin:admin"  http://localhost:7180/api/version` -z ] ;
#     do
#     echo "waiting 10s for CM to come up..";
#     sleep 10;
# done

echo "-- Now CM is started and the next step is to automate using the CM API"

pip install --upgrade pip cm_client

sed -i "s/YourHostname/`hostname -f`/g" /home/cloudera/CDP-Private-Trial/CDPDCTrial/scripts/create_cluster.py
sed -i "s/YourHostname/`hostname -f`/g" /home/cloudera/CDP-Private-Trial/CDPDCTrial/scripts/create_cluster.py

# python /home/cloudera/CDP-Private-Trial/CDPDCTrial/scripts/create_cluster.py /home/cloudera/CDP-Private-Trial/CDPDCTrial/conf/wasp-services-trial.json

# rm -f /opt/cloudera/parcel-repo/*


# usermod cloudera -G hadoop
# usermod --shell /bin/bash hdfs  
# hdfs dfs -mkdir /user/cloudera
# hdfs dfs -chown cloudera:hadoop /user/cloudera
# hdfs dfs -mkdir /user/admin
# hdfs dfs -chown admin:hadoop /user/admin
# hdfs dfs -chmod -R 0755 /tmp

