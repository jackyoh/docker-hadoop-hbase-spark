FROM centos:6.6
MAINTAINER Docker Jack <jack@is-land.com.tw>

USER root

# Install dev tools
RUN yum clean all; \
    rpm --rebuilddb; \
    yum install -y curl which tar sudo wget openssh-server openssh-clients rsync mysql mysql-server

RUN yum update -y libselinux
RUN yum install -y lsof ntpd git telnet
RUN yum groupinstall -y "Development Tools"


# Gen ssh /root/.ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys


RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config

# Start ssh daemon
ENTRYPOINT service sshd start && bash

# Install JDK
RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'

RUN cd /
RUN tar -zxvf jdk-7u71-linux-x64.tar.gz

# Download hadoop,hbase,spark
RUN wget https://www.apache.org/dist/hadoop/core/hadoop-2.7.0/hadoop-2.7.0.tar.gz -P /opt
RUN wget https://archive.apache.org/dist/hbase/0.98.19/hbase-0.98.19-hadoop2-bin.tar.gz -P /opt
RUN wget https://www.apache.org/dist/spark/spark-1.6.1/spark-1.6.1-bin-hadoop2.6.tgz -P /opt


# Unzip hadoop,hbaes,hive,spark
RUN cd /opt && tar zxvf /opt/hadoop-2.7.0.tar.gz
RUN cd /opt && tar zxvf /opt/hbase-0.98.19-hadoop2-bin.tar.gz
RUN cd /opt && tar zxvf /opt/spark-1.6.1-bin-hadoop2.6.tgz

RUN mv /opt/spark-1.6.1-bin-hadoop2.6 /opt/spark
RUN mv /opt/hadoop-2.7.0 /opt/hadoop
RUN mv /opt/hbase-0.98.19-hadoop2 /opt/hbase


#Copy Configuration file
COPY hadoopConfig /opt/hadoop/etc/hadoop
ARG HADOOP_MASTER_HOST_NAME=docker-server-a1
RUN sed s/HADOOP_MASTER_HOST_NAME/${HADOOP_MASTER_HOST_NAME}/ /opt/hadoop/etc/hadoop/core-site.xml.template > /opt/hadoop/etc/hadoop/core-site.xml
RUN sed s/HADOOP_MASTER_HOST_NAME/${HADOOP_MASTER_HOST_NAME}/ /opt/hadoop/etc/hadoop/yarn-site.xml.template > /opt/hadoop/etc/hadoop/yarn-site.xml
RUN sed s/HADOOP_MASTER_HOST_NAME/${HADOOP_MASTER_HOST_NAME}/ /opt/hadoop/etc/hadoop/hdfs-site.xml.template > /opt/hadoop/etc/hadoop/hdfs-site.xml


COPY hbaseConfig /opt/hbase/conf
RUN sed s/HBASE_MASTER_HOST_NAME/${HADOOP_MASTER_HOST_NAME}/ /opt/hbase/conf/hbase-site.xml.template>/opt/hbase/conf/hbase-site.xml
RUN rm -rf /opt/hbase/conf/regionservers
RUN ln -s /opt/hadoop/etc/hadoop/slaves /opt/hbase/conf/regionservers

COPY sparkConfig /opt/spark/conf
RUN sed s/HADOOP_MASTER_HOST_NAME/${HADOOP_MASTER_HOST_NAME}/ /opt/spark/conf/spark-defaults.conf.template > /opt/spark/conf/spark-defaults.conf

#Setting environment variable
RUN echo "export JAVA_HOME=/jdk1.7.0_71">>/etc/profile
RUN echo "export HADOOP_HOME=/opt/hadoop">>/etc/profile
RUN echo "export HBASE_HOME=/opt/hbase">>/etc/profile
RUN echo "export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop">>/etc/profile
RUN echo "export PATH=/opt/hadoop/bin:/opt/hbase/bin:/jdk1.7.0_71/bin:$PATH">>/etc/profile


