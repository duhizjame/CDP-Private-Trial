FROM ubuntu:18.04
ENV container docker
# RUN apt-get -y install httpd; apt-get clean all; systemctl enable httpd.service
# RUN apt-get -y install systemd; systemctl enable systemd;
EXPOSE 80 7182 7180 9000 9001
RUN apt-get update
RUN apt-get install -y net-tools
# RUN apt-get install -y mariadb-server mariadb-client
# RUN apt-get install -y ntp 
RUN apt-get install -y openssh-server openssh-client
RUN echo "-- Configure user cloudera with passwordless"
RUN useradd cloudera -d /home/cloudera -p cloudera
RUN apt-get install -y systemd
# RUN usermod -aG wheel cloudera
RUN echo "-- Install Java OpenJDK8 and other tools"
RUN apt-get install -y openjdk-8-jdk vim wget curl git rng-tools
RUN apt-get install -y software-properties-common
RUN apt-get install -y gnupg
RUN wget https://archive.cloudera.com/cm7/7.4.4/ubuntu1804/apt/archive.key
RUN apt-key add archive.key 
# RUN touch /etc/sysconfig/network
RUN wget https://archive.cloudera.com/cm7/7.4.4/ubuntu1804/apt/cloudera-manager-trial.list 
RUN add-apt-repository "deb [arch=amd64] http://archive.cloudera.com/cm7/7.4.4/ubuntu1804/apt bionic-cm7.4.4 contrib"
RUN apt-get update
RUN apt-get install -y python python-pip
# RUN sed -i '' -e 's/server_host=.*/server_host=cloudera/' /etc/cloudera-scm-agent/config.ini
# RUN sed -i '' -e 's/# listening_ip=.*/listening_ip=172.17.0.2/' /etc/cloudera-scm-agent/config.ini
# RUN curl -O https://bootstrap.pypa.io/pip/2.7/get-pip.py; python get-pip.py;
RUN pip install --upgrade pip cm_client
RUN git clone https://github.com/duhizjame/CDP-Private-Trial.git; chmod -R 777 ./CDP-Private-Trial
RUN cd /
RUN systemctl list-unit-files --type service -all
# RUN systemctl enable cloudera-scm-manager 
# RUN systemctl enable cloudera-scm-agent
VOLUME [ "/sys/fs/cgroup" ]
COPY entrypoint.sh entrypoint.sh
RUN chmod 777 entrypoint.sh
RUN ls -l
CMD ["/bin/bash", "/entrypoint.sh"] 
