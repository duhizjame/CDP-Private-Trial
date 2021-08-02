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
RUN useradd cloudera -d /home/cloudera -p cloudera
RUN cd /home/cloudera; curl -O https://bootstrap.pypa.io/pip/2.7/get-pip.py; python get-pip.py
RUN yum install  -y git
RUN pip install --upgrade pip cm_client
RUN cd /home/cloudera; git clone https://github.com/carrossoni/CDPDCTrial.git; chmod -R 777 ./CDPDCTrial
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]