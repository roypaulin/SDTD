#!/bin/bash

# PART 1: SETTING KUBERNETES

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
BASE_DIR="$( cd -P "$( dirname "$SOURCE" )/../.." >/dev/null 2>&1 && pwd )"

UTILS_DIR="${BASE_DIR}/utils"
KUBERNETES_DIR="${BASE_DIR}/clusters/kubernetes"

if [ ! -d ${UTILS_DIR} ]; then
	mkdir ${UTILS_DIR}
fi

echo -e "\n-> KUBERNETES: Checking if needed softwares are installed..."

# Installing aws (if not already installed)
echo -e "\n-> Checking if aws is installed..."

if [ -f ${UTILS_DIR}/aws ]; then
	AWS=${UTILS_DIR}/aws
elif [ -x "$(command -v aws)" ]; then
	AWS="$(command -v aws)"
else
	echo -e "\naws not found. Installing aws into folder utils..."

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

	./aws/install -i ${UTILS_DIR} -b ${UTILS_DIR}

	rm -rf ./aws

	mv ${UTILS_DIR}/aws2 ${UTILS_DIR}/aws

	AWS=${UTILS_DIR}/aws
fi

if [ -x "$(command -v ${AWS})" ]; then
	echo -e "OK: aws ready to be used!"
else 
	echo -e "\nProblem installing aws.\n"
  rm -rf ${UTILS_DIR}/aws* >/dev/null 2>&1
  exit 1
fi

# Installing kops (if not already installed)
echo -e "\n-> Checking if kops is installed..."

if [ -f ${UTILS_DIR}/kops ]; then
	KOPS=${UTILS_DIR}/kops
elif [ -x "$(command -v kops)" ]; then
	KOPS="$(command -v kops)"
else
	echo -e "\nkops not found. Installing kops into folder utils..."

	if [ "$(uname)" == "Darwin" ]; then # MacOS
  	curl -o ${UTILS_DIR}/kops -L https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-darwin-amd64
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then # Linux
		curl  -o ${UTILS_DIR}/kops -L https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
	else
		echo -e "\nError: Unsupported OS. Please change to macOS or Linux.\n"
		exit 1
	fi

	chmod +x ${UTILS_DIR}/kops

	KOPS=${UTILS_DIR}/kops
fi

if [ -x "$(command -v ${KOPS})" ]; then
  echo -e "OK: kops ready to be used!"
else 
	echo -e "\nProblem installing kops.\n"
  rm ${UTILS_DIR}/kops >/dev/null 2>&1
  exit 1
fi

# Installing kubectl (if not already installed)
echo -e "\n-> Checking if kubectl is installed..."

if [ -f ${UTILS_DIR}/kubectl ]; then
	KUBECTL=${UTILS_DIR}/kubectl
elif [ -x "$(command -v kubectl)" ]; then
	KUBECTL="$(command -v kubectl)"
else
	echo -e "\nkubectl not found. Installing kubectl into folder utils..."

	if [ "$(uname)" == "Darwin" ]; then # MacOS
  	curl -o ${UTILS_DIR}/kubectl -L "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then # Linux
		curl -o ${UTILS_DIR}/kubectl -L https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
	else
		echo -e "\nError: Unsupported OS. Please change to macOS or Linux.\n"
		exit 1
	fi

	chmod +x ${UTILS_DIR}/kubectl

	KUBECTL=${UTILS_DIR}/kubectl
fi

if [ -x "$(command -v ${KUBECTL})" ]; then
	echo -e "OK: kubectl ready to be used!"
else 
	echo -e "\nProblem installing kubectl.\n"
  rm ${UTILS_DIR}/kubectl >/dev/null 2>&1
  exit 1
fi

# Load environment variables
source ${BASE_DIR}/env/aws.env

# Cluster Setup
CLUSTER_NAME="sdtd.k8s.local"
ZONE="us-east-2a"
MASTER_SIZE="t2.large"
NODE_SIZE="t2.large"
NODE_COUNT="3"

# Check if asked to destroy
if [ "$1" == "destroy" ]; then
  echo -e "\n-> Destroying kubernetes cluster..."
  ${KOPS} delete cluster ${CLUSTER_NAME} --yes
  if [ $? -eq 0 ]; then
  	echo -e "\nOK: Kubernetes cluster destroyed!"
  	rm ${BASE_DIR}/ssh_keys/kubernetes-key* > /dev/null 2>&1
    rm ${KUBERNETES_DIR}/dashboard_token.txt > /dev/null 2>&1
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

echo -e "\n-> Waiting for cluster to finish initial setup..."
echo -e "NOTE: This might take up to 5 minutes!!\n"

#TODO FIX THIS LOOP
${KOPS} validate cluster | grep "is ready"

CLUSTER_NOT_READY=$?

while [[ CLUSTER_NOT_READY -ne 0 ]]
do
  echo -e "Cluster not ready. Please wait...\n"
  sleep 90
  ${KOPS} validate cluster | grep "is ready"
  CLUSTER_NOT_READY=$?
done

echo -e "\nOK: Kubernetes cluster successfully deployed!"

echo -e "-> Creating Kubernetes Dashboard..."

${KUBECTL} apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended.yaml

${KUBECTL} apply -f ${KUBERNETES_DIR}/admin-role-binding.yaml
${KUBECTL} apply -f ${KUBERNETES_DIR}/dashboard-admin-user.yaml

${KUBECTL} -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}') | awk '/token:/ {print $2}' > ${KUBERNETES_DIR}/dashboard_token.txt

echo -e "\nKubernetes dashboard created!"
echo -e "\nLaunch the command 'kubectl proxy &' and access it on the following link:" 
echo -e "\nhttp://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo -e "\nWith the token found on file clusters/kubernetes/dashboard_token.txt\n"
cat ${KUBERNETES_DIR}/dashboard_token.txt

exit 0