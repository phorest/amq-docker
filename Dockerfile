FROM docker.phorest.com/java:8
MAINTAINER “Dan Walsh” <dwalsh@redhat.com>
ENV container docker
RUN yum -y update; yum clean all
RUN yum -y install systemd; yum clean all;
RUN yum install -y which unzip openssh-server sudo openssh-clients && yum clean all

# enable no pass and speed up authentication
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/;s/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

# enabling sudo group
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
# enabling sudo over ssh
RUN sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers

ENV INSTALL4J_JAVA_HOME $JAVA_HOME/jre

# add a user for the application, with sudo permissions
RUN useradd -m activemq ; echo activemq: | chpasswd ; usermod -a -G wheel activemq

# command line goodies
RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /etc/profile
RUN echo "alias ll='ls -l --color=auto'" >> /etc/profile
RUN echo "alias grep='grep --color=auto'" >> /etc/profile


WORKDIR /home/activemq

USER activemq

ENV ACTIVE_MQ_VERSION 5.14.0
RUN curl  --output apache-mq.zip http://central.maven.org/maven2/org/apache/activemq/apache-activemq/$ACTIVE_MQ_VERSION/apache-activemq-$ACTIVE_MQ_VERSION-bin.zip
RUN unzip apache-mq.zip
RUN rm apache-mq.zip
RUN chown -R activemq:activemq apache-activemq-$ACTIVE_MQ_VERSION

WORKDIR /home/activemq/apache-activemq-$ACTIVE_MQ_VERSION/conf

WORKDIR /home/activemq/apache-activemq-$ACTIVE_MQ_VERSION/bin
RUN chmod u+x ./activemq

WORKDIR /home/activemq/apache-activemq-$ACTIVE_MQ_VERSION/

# ensure we have a log file to tail
RUN mkdir -p data/
RUN echo >> data/activemq.log
EXPOSE 22 1099 61616 8161 5672 61613 1883 61614

WORKDIR /home/activemq/apache-activemq-$ACTIVE_MQ_VERSION/conf
RUN rm -f startup.sh
RUN curl   --output startup.sh  https://raw.githubusercontent.com/phorest/amq-docker/master/activemq-cluster-config.sh 

RUN chmod u+x ./startup.sh
CMD  /home/activemq/apache-activemq-$ACTIVE_MQ_VERSION/conf/startup.sh
