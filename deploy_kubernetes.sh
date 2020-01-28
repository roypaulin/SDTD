#!/bin/bash

## DEPLOYING KUBERNETES WITH KOPS ##

function aborting() {
  echo -e "\nAborting script.\n"
  exit 0
}

trap aborting SIGINT

# Get current directory without symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
BASE_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

KUBERNETES_DIR="${BASE_DIR}/kubernetes"

if [ ! -d ${KUBERNETES_DIR}/utils ]; then
	mkdir ${KUBERNETES_DIR}/utils
fi

echo -e "\n-> Checking if needed softwares are installed..."

# Installing aws (if not already installed)
echo -e "\n-> Checking if aws is installed..."

if [ -f ${KUBERNETES_DIR}/utils/aws ]; then
	AWS=${KUBERNETES_DIR}/utils/aws
elif [ -x "$(command -v aws)" ]; then
	AWS="$(command -v aws)"
else
	echo -e "\naws not found. Installing aws into folder kubernetes/utils..."

	if [ "$(uname)" == "Darwin" ]; then # MacOS
		AWS_FILE=awscli-exe-macos.zip
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then # Linux
		AWS_FILE=awscli-exe-linux-x86_64.zip
	else
		echo -e "\nError: Unsupported OS. Please change to macOS or Linux.\n"
		exit 1
	fi

  curl "https://d1vvhvl2y92vvt.cloudfront.net/${AWS_FILE}" -o "awscliv2.zip"

	unzip awscliv2.zip

	rm awscliv2.zip

	./aws/install -i ${KUBERNETES_DIR}/utils -b ${KUBERNETES_DIR}/utils

	rm -rf ./aws

	mv ${KUBERNETES_DIR}/utils/aws2 ${KUBERNETES_DIR}/utils/aws

	AWS=${KUBERNETES_DIR}/utils/aws
fi

if [ -x "$(command -v ${AWS})" ]; then
	echo -e "OK: aws ready to be used!"
else 
	echo -e "\nProblem installing aws.\n"
  rm -rf ${KUBERNETES_DIR}/utils/aws* >/dev/null 2>&1
  exit 1
fi

# Installing kops (if not already installed)
echo -e "\n-> Checking if kops is installed..."

if [ -f ${KUBERNETES_DIR}/utils/kops ]; then
	KOPS=${KUBERNETES_DIR}/utils/kops
elif [ -x "$(command -v kops)" ]; then
	KOPS="$(command -v kops)"
else
	echo -e "\nkops not found. Installing kops into folder kubernetes/utils..."

	if [ "$(uname)" == "Darwin" ]; then # MacOS
  	curl -o ${KUBERNETES_DIR}/utils/kops -L https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-darwin-amd64
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then # Linux
		curl  -o ${KUBERNETES_DIR}/utils/kops -L https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
	else
		echo -e "\nError: Unsupported OS. Please change to macOS or Linux.\n"
		exit 1
	fi

	chmod +x ${KUBERNETES_DIR}/utils/kops

	KOPS=${KUBERNETES_DIR}/utils/kops
fi

if [ -x "$(command -v ${KOPS})" ]; then
  echo -e "OK: kops ready to be used!"
else 
	echo -e "\nProblem installing kops.\n"
  rm ${KUBERNETES_DIR}/utils/kops >/dev/null 2>&1
  exit 1
fi

# Installing kubectl (if not already installed)
echo -e "\n-> Checking if kubectl is installed..."

if [ -f ${KUBERNETES_DIR}/utils/kubectl ]; then
	KUBECTL=${KUBERNETES_DIR}/utils/kubectl
elif [ -x "$(command -v kubectl)" ]; then
	KUBECTL="$(command -v kubectl)"
else
	echo -e "\nkubectl not found. Installing kubectl into folder kubernetes/utils..."

	if [ "$(uname)" == "Darwin" ]; then # MacOS
  	curl -o ${KUBERNETES_DIR}/utils/kubectl -L "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then # Linux
		curl -o ${KUBERNETES_DIR}/utils/kubectl -L https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
	else
		echo -e "\nError: Unsupported OS. Please change to macOS or Linux.\n"
		exit 1
	fi

	chmod +x ${KUBERNETES_DIR}/utils/kubectl

	KUBECTL=${KUBERNETES_DIR}/utils/kubectl
fi

if [ -x "$(command -v ${KUBECTL})" ]; then
	echo -e "OK: kubectl ready to be used!"
else 
	echo -e "\nProblem installing kubectl.\n"
  rm ${KUBERNETES_DIR}/utils/kubectl >/dev/null 2>&1
  exit 1
fi

# Checking if Java8 installed
echo -e "\n-> Checking if Java 8 is installed and JAVA_HOME is set..."

JAVA_VERSION="$(java -version 2>&1 >/dev/null | egrep '\S+\s+version')"
if [[ ! ${JAVA_VERSION} == *"1.8"* ]]; then
  echo -e "Error: Please install Java 1.8\n"
  exit 1
elif [ ! -z ${JAVA_HOME} ]; then
  echo -e "Error: Please set JAVA_HOME\n"
  exit 1
else 
  echo -e "OK: Java 1.8 installed and JAVA_HOME set!"
fi

# Installing spark (if not already installed)
echo -e "\n-> Checking if spark is installed..."

if [ -f ${KUBERNETES_DIR}/utils/spark/bin/spark-submit ]; then
  SPARK_SUBMIT=${KUBERNETES_DIR}/utils/spark/bin/spark-submit
elif [ -x "$(command -v spark-submit)" ]; then
  SPARK_SUBMIT="$(command -v spark-submit)"
else
  echo -e "\nkubectl not found. Installing kubectl into folder kubernetes/utils..."

  wget "https://archive.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz"

  tar -xvf spark-2.4.4-bin-hadoop2.7.tgz

  rm spark-2.4.4-bin-hadoop2.7.tgz

  mv spark-2.4.4-bin-hadoop2.7 ${KUBERNETES_DIR}/utils/spark

  chmod +x ${KUBERNETES_DIR}/utils/spark/bin/spark-submit

  export SPARK_HOME=${KUBERNETES_DIR}/utils/spark
  export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/build:$PYTHONPATH
  export PYTHONPATH=$SPARK_HOME/python/lib/py4j-0.10.4-src.zip:$PYTHONPATH

  SPARK_SUBMIT=${KUBERNETES_DIR}/utils/spark/bin/spark-submit
fi

if [ -x "$(command -v ${SPARK_SUBMIT})" ]; then
  echo -e "OK: spark ready to be used!"
else 
  echo -e "\nProblem installing spark.\n"
  rm -rf ${KUBERNETES_DIR}/utils/spark* >/dev/null 2>&1
  exit 1
fi

# Installing sbt (if not already installed)
echo -e "\n-> Checking if sbt is installed..."

if [ -f ${KUBERNETES_DIR}/utils/sbt ]; then
  SBT=${KUBERNETES_DIR}/utils/sbt
elif [ -x "$(command -v sbt)" ]; then
  SBT="$(command -v sbt)"
else
  echo -e "\nsbt not found. Installing sbt into folder kubernetes/utils..."

  wget "https://piccolo.link/sbt-1.3.7.zip"

  unzip sbt-1.3.7.zip -d ${KUBERNETES_DIR}/utils/

  rm sbt-1.3.7.zip

  chmod +x ${KUBERNETES_DIR}/utils/sbt/bin/sbt

  SBT=${KUBERNETES_DIR}/utils/sbt/bin/sbt
fi

if [ -x "$(command -v ${SBT})" ]; then
  echo -e "OK: sbt ready to be used!"
else 
  echo -e "\nProblem installing sbt.\n"
  rm -rf ${KUBERNETES_DIR}/utils/sbt >/dev/null 2>&1
  exit 1
fi

# Load environment variables
source ${BASE_DIR}/env/aws.env

# Cluster Setup
CLUSTER_NAME="sdtd.k8s.local"
ZONE="us-east-2a"
MASTER_SIZE="t3.large"
NODE_SIZE="t3.large"
NODE_COUNT="3"

# Check if asked to destroy
if [ "$1" == "destroy" ]; then
  echo -e "\n-> Destroying kubernetes cluster..."
  ${KOPS} delete cluster ${CLUSTER_NAME} --yes
  if [ $? -eq 0 ]; then
  	echo -e "\nOK: Kubernetes cluster destroyed!\n"
  	rm ${BASE_DIR}/ssh_keys/kubernetes-key* > /dev/null 2>&1
  	#TODO remove spark part
  	echo -e "\n-> Removing s3 bucket with kops state...\n"
  	${AWS} s3 rb ${KOPS_STATE_STORE} --region=${AWS_REGION} --force 
  	if [ $? -eq 0 ]; then
  	  echo -e "\nOK: Bucket removed!\n"
  	  exit 0
  	else
  	  echo -e "\nProblem deleting bucket.\n"
  	  exit 1
  	fi
  else
    echo -e "\nProblem removing kubernetes cluster.\n"
    exit 1
  fi
fi

# Create folder ssh_keys and delete previous keys (if they exist)
if [ -f ${BASE_DIR}/ssh_keys/kubernetes-key ]; then
  echo -e "\nRemoving old ssh-key..."
  rm ${BASE_DIR}/ssh_keys/kubernetes-key*
elif [ ! -d ${BASE_DIR}/ssh_keys ]; then
	mkdir ${BASE_DIR}/ssh_keys
fi

# Create ssh keypair on folder ssh_keys
echo -e "\n-> Creating new ssh key 'kubernetes-key' on folder ssh_keys\n"
ssh-keygen -t rsa -N "" -f ${BASE_DIR}/ssh_keys/kubernetes-key

# Create bucket s3 to store states (before export your AWS Credentials)
echo -e "\n-> Creating s3 bucket to save kops state...\n"

${AWS} s3 mb ${KOPS_STATE_STORE} --region ${AWS_REGION}

# Create cluster
echo -e "\n-> Creating kops cluster...\n"

${KOPS} create cluster ${CLUSTER_NAME} \
	--node-count ${NODE_COUNT} \
	--zones ${ZONE} \
	--node-size ${NODE_SIZE} \
	--master-size ${MASTER_SIZE} \
	--master-zones ${ZONE} \
	--ssh-public-key ${BASE_DIR}/ssh_keys/kubernetes-key.pub \
	--yes

# Deploy cluster to AWS
echo -e "\n-> Deploying kops cluster on AWS...\n"

${KOPS} update cluster ${CLUSTER_NAME} --yes

echo -e "\n-> Waiting for cluster to be running...\n"

while [[ $(${KOPS} validate cluster) != *"is ready"* ]]
do
  echo -e "Please wait..."
  sleep 30
done
echo -e "\nOK: Cluster ready!"


#TODO add loop to check if cluster is up with
# ${KOPS} validate cluster | grep...

# 8) Install Dashboard
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc1/aio/deploy/recommended.yaml

# Getting Bearer Token
# kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
# kubectl proxy &

# Accessing the dashboard:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# TODO: add spark
# cd ${KUBERNETES_DIR}/twitter

# # Build jar file
# echo -e "\n-> Generating JAR that will be deployed on spark...\n"

# ${SBT} assembly

# if [ $? -eq 0 ]; then
#   echo -e "\nOK: jar succesfully built!"
#   mv target/scala-2.11/SDTD-assembly-1.0.jar ${BASE_DIR}/
#   ./clean-scala.sh
# else
#   echo -e "\nProblem running sbt assembly.\n"
# fi

# Deploy spark


# USEFULL COMMANDS:
# kops get cluster # List clusters
# kops edit cluster ${CLUSTER_NAME} # Edit cluster
# kops edit ig --name=${CLUSTER_NAME} nodes # Edit node instances
# kops edit ig --name=${CLUSTER_NAME} master-us-east-1c # Edit master instances
# kops update cluster --yes # Update cluster
# kops rolling-update cluster # Immediat deploy
