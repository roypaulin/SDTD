#!/bin/bash

function aborting() {
  echo -e "\nAborting script.\n"
  exit 0
}

trap aborting SIGINT

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
BASE_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

KAFKA_DIR="${BASE_DIR}/kafka"

if [ ! -d ${KAFKA_DIR}/utils ]; then
  mkdir ${KAFKA_DIR}/utils
fi

# Installing terraform (if not already installed)
echo -e "\n-> Checking if terraform is installed..."

if [ -f ${KAFKA_DIR}/utils/terraform ]; then
  TERRAFORM=${KAFKA_DIR}/utils/terraform
elif [ -x "$(command -v terraform)" ]; then
  TERRAFORM="$(command -v terraform)"
else
  echo -e "\nterraform not found. Installing terraform into folder kafka/utils..."

  if [ "$(uname)" == "Darwin" ]; then # MacOS
    TERRAFORM_FILE=terraform_0.12.12_darwin_amd64.zip
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then # Linux
    TERRAFORM_FILE=terraform_0.12.12_linux_amd64.zip
  else
    echo -e "\nError: Unsupported OS. Please change to macOS or Linux.\n"
    exit 1
  fi

  curl "https://releases.hashicorp.com/terraform/0.12.12/${TERRAFORM_FILE}}" -o "terraform.zip"

  unzip terraform.zip -d ${KAFKA_DIR}/utils/

  rm terraform.zip

  chmod +x ${KAFKA_DIR}/utils/terraform

  TERRAFORM=${KAFKA_DIR}/utils/terraform
fi

if [ -x "$(command -v ${TERRAFORM})" ]; then
  echo -e "OK: terraform ready to be used!"
else 
  echo -e "\nProblem installing terraform.\n"
  rm ${KAFKA_DIR}/utils/terraform >/dev/null 2>&1
fi

# Check if ansible is installed
echo -e "\n-> Checking if ansible is installed..."

if [ -x "$(command -v ansible-playbook)" ]; then
  echo -e "OK: ansible ready to be used!"
else 
  echo -e "\nAnsible not installed. Please install the good version for your OS."
  echo -e "Info: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html\n"
fi

# Load environment variables
source ${BASE_DIR}/env/aws.env

# Copy templates
cp ${BASE_DIR}/env/twitter.env ${KAFKA_DIR}/ansible/roles/twitter.environment/templates/.env

# Check if asked to destroy
if [ "$1" == "destroy" ]; then
  echo -e "\n-> Destroying kafka cluster...\n"
  cd ${KAFKA_DIR}/terraform
  ${TERRAFORM} destroy -auto-approve
  if [ $? -eq 0 ]; then
  	rm ${KAFKA_DIR}/terraform/*.tfstate* > /dev/null 2>&1
    rm ${KAFKA_DIR}/terraform/.terraform > /dev/null 2>&1
    rm ${BASE_DIR}/SDTD-assembly-1.0.jar > /dev/null 2>&1
    rm ${BASE_DIR}/ssh_keys/kafka-key* > /dev/null 2>&1
    rm ${BASE_DIR}/ssh_config > /dev/null 2>&1
  	echo -e "OK: Kafka cluster removed!\n"
  	exit 0
  else
    echo -e "\nProblem removing kafka cluster.\n"
    exit 1
  fi
fi

# Create folder ssh_keys and delete previous keys (if they existed)
if [ -f ${BASE_DIR}/ssh_keys/kafka-key ]; then
  echo -e "\n-> Removing old ssh-key..."
  rm ${BASE_DIR}/ssh_keys/kafka-key*
elif [ ! -d ${BASE_DIR}/ssh_keys ]; then
	mkdir ${BASE_DIR}/ssh_keys
fi

# Create ssh keypair on folder ssh_keys
echo -e "\n-> Creating new ssh key 'kafka-key' on folder ssh_keys\n"
ssh-keygen -t rsa -N "" -f ${BASE_DIR}/ssh_keys/kafka-key

echo -e "\n-> Creating instances with Terraform..."

# Deploy instances with Terraform
cd ${KAFKA_DIR}/terraform

${TERRAFORM} init
${TERRAFORM} plan
${TERRAFORM} apply -auto-approve

if [ ! $? -eq 0 ]; then
	echo -e "\nTerraform apply failed. Check messages to fix problems.\n"
	exit 1
fi

sleep 20

echo -e "\n-> Installing Kafka using Ansible...\n"

# Install Kafka on instances
cd ${KAFKA_DIR}/ansible

ansible-playbook all.yml

if [ $? -eq 0 ]; then
	mv ssh_config ${BASE_DIR}/
  mv twitter-subscriber.scala ${BASE_DIR}/
	echo -e "\nInstallion completed! You can access your machines with ssh -F ssh_config <host-name>"
else
	echo -e "\nInstallion failed. Check messages to fix problems.\n"
  exit 1
fi

cd ${BASE_DIR}

echo -e "\n-> Starting kafka publisher..."

# Start python script on control-center
ssh -f -F ssh_config kafka-control-center-01 'nohup python3 -u twitter-publisher.py > publisher.log &'

echo -e "\n-> Copying twitter-subscriber.scala to kubernetes/twitter/src/main/scala/ ..."

if [ ! -d ${BASE_DIR}/kubernetes/twitter/src/main/scala ]; then
  mkdir -p ${BASE_DIR}/kubernetes/twitter/src/main/scala >/dev/null 2>&1
fi

# Moving scala file created by ansible to good folder to build jar file
mv  twitter-subscriber.scala ${BASE_DIR}/kubernetes/twitter/src/main/scala/

echo -e "OK: file successfully copied to src folder from kubernetes!\n"
exit 0