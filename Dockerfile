FROM centos/systemd:latest
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
RUN yum -y install httpd; yum clean all; systemctl enable httpd.service
EXPOSE 80 7182 7180 9000 9001
RUN yum install -y net-tools
RUN yum install -y mariadb
RUN yum install -y ntp 
RUN yum install -y openssh-server openssh-client
RUN touch /etc/sysconfig/network
RUN cd /; wget https://archive.cloudera.com/cm7/7.4.4/redhat7/yum/cloudera-manager-trial.repo -P /etc/yum.repos.d/
RUN yum install -y cloudera-manager-agent cloudera-manager-daemons cloudera-manager-server; \
    sed -i '' -e 's/server_host=.*/server_host=cloudera/' /etc/cloudera-scm-agent/config.ini; \
    sed -i '' -e 's/# listening_ip=.*/listening_ip=172.17.0.2/' /etc/cloudera-scm-agent/config.ini 
RUN useradd cloudera -d /home/cloudera -p cloudera
RUN cd /home/cloudera; curl -O https://bootstrap.pypa.io/pip/2.7/get-pip.py; python get-pip.py;
RUN yum install  -y git
RUN pip install --upgrade pip cm_client
RUN cd /home/cloudera; git clone https://github.com/duhizjame/CDP-Private-Trial.git; chmod -R 777 ./CDP-Private-Trial
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
