# Pour créer l'image docker build . -t application_manager
# Image de base
FROM ubuntu:18.04

# Installing some dependencies
RUN apt-get update && apt-get install -y apt-utils software-properties-common wget curl unzip sudo less vim openssl python3-pip

# Install Java.
RUN apt-get install -y openjdk-8-jdk openjdk-8-jre

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Install Docker
RUN apt install -y docker.io
RUN service docker start

# Install ansible
RUN apt-add-repository ppa:ansible/ansible
RUN apt-get update
RUN apt-get install -y ansible

# Install terraform
RUN wget https://releases.hashicorp.com/terraform/0.12.12/terraform_0.12.12_linux_amd64.zip 
RUN unzip ./terraform_0.12.12_linux_amd64.zip
RUN rm ./terraform_0.12.12_linux_amd64.zip
RUN mv terraform /usr/local/bin

# Install kops
RUN curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
RUN chmod a+x ./kops
RUN mv ./kops /usr/local/bin/

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
RUN chmod a+x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Install spark
RUN wget "https://archive.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz"
RUN tar -xvf spark-2.4.4-bin-hadoop2.7.tgz
RUN rm spark-2.4.4-bin-hadoop2.7.tgz
RUN mv ./spark-2.4.4-bin-hadoop2.7 /usr/local/spark

ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH ${SPARK_HOME}/python:$SPARK_HOME/python/build:$PYTHONPATH
ENV PYTHONPATH ${SPARK_HOME}/python/lib/py4j-0.10.4-src.zip:$PYTHONPATH
ENV PATH ${SPARK_HOME}/bin:$PATH

# Install sbt
RUN wget "https://piccolo.link/sbt-1.3.7.zip"
RUN unzip sbt-1.3.7.zip -d ${UTILS_DIR}/
RUN rm sbt-1.3.7.zip
RUN chmod a+x ./sbt/
RUN mv ./sbt /usr/local/bin/sbt

# Install aws-cli
RUN apt-get install -y awscli

# Cleaning cache
RUN rm -rf /var/lib/apt/lists/*

# Copying code to deploy clusters

WORKDIR /home/sdtd/

COPY . /home/sdtd/

# Install pip dependencies
RUN pip3 install -r /home/sdtd/requirements.txt

RUN chmod a+x ./deploy.sh
RUN chmod a+x ./destroy.sh

RUN chmod -R a+x ./clusters/*.sh 

# Command that will be runned when starting container
CMD ["bash"]