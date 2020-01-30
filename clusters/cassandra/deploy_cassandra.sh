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
BASE_DIR="$( cd -P "$( dirname "$SOURCE" )/../.." >/dev/null 2>&1 && pwd )"

UTILS_DIR="${BASE_DIR}/utils"
CASSANDRA_DIR="${BASE_DIR}/clusters/cassandra"

if [ ! -d ${UTILS_DIR} ]; then
  mkdir ${UTILS_DIR}/
fi

echo -e "\n-> CASSANDRA: Checking if needed softwares are installed..."

# Installing terraform (if not already installed)
echo -e "\n-> Checking if terraform is installed..."

if [ -f ${UTILS_DIR}/terraform ]; then
  TERRAFORM=${UTILS_DIR}/terraform
elif [ -x "$(command -v terraform)" ]; then
  TERRAFORM="$(command -v terraform)"
else
  echo -e "\nterraform not found. Installing terraform into folder utils..."

  if [ "$(uname)" == "Darwin" ]; then # MacOS
    TERRAFORM_FILE=terraform_0.12.12_darwin_amd64.zip
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then # Linux
    TERRAFORM_FILE=terraform_0.12.12_linux_amd64.zip
  else
    echo -e "\nError: Unsupported OS. Please change to macOS or Linux.\n"
    exit 1
  fi

  curl "https://releases.hashicorp.com/terraform/0.12.12/${TERRAFORM_FILE}}" -o "terraform.zip"

  unzip terraform.zip -d ${UTILS_DIR}/

  rm terraform.zip

  chmod +x ${UTILS_DIR}/terraform

  TERRAFORM=${UTILS_DIR}/terraform
fi

if [ -x "$(command -v ${TERRAFORM})" ]; then
  echo -e "OK: terraform ready to be used!"
else 
  echo -e "\nProblem installing terraform.\n"
  rm ${UTILS_DIR}/terraform >/dev/null 2>&1
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

# Check if asked to destroy
if [ "$1" == "destroy" ]; then
  echo -e "\n-> Destroying cassandra cluster...\n"
  cd ${CASSANDRA_DIR}/terraform
  ${TERRAFORM} destroy -auto-approve
  if [ $? -eq 0 ]; then
    rm -rf ${CASSANDRA_DIR}/terraform/.terraform > /dev/null 2>&1
    rm ${CASSANDRA_DIR}/ansible/ssh_config > /dev/null 2>&1
  	rm ${CASSANDRA_DIR}/terraform/*.tfstate* > /dev/null 2>&1
    rm ${CASSANDRA_DIR}/readDB.py > /dev/null 2>&1
    rm ${BASE_DIR}/ssh_keys/cassandra-key* > /dev/null 2>&1
    rm ${BASE_DIR}/ssh_config > /dev/null 2>&1
  	echo -e "OK: Cassandra cluster removed!\n"
  	exit 0
  else
    echo -e "\nProblem removing cassandra cluster.\n"
    exit 1
  fi
fi

# Create folder ssh_keys and delete previous keys (if they existed)
if [ -f ${BASE_DIR}/ssh_keys/cassandra-key ]; then
  echo -e "\n-> Removing old ssh-key..."
  rm ${BASE_DIR}/ssh_keys/cassandra-key*
elif [ ! -d ${BASE_DIR}/ssh_keys ]; then
	mkdir ${BASE_DIR}/ssh_keys
fi

# Create ssh keypair on folder ssh_keys
echo -e "\n-> Creating new ssh key 'cassandra-key' on folder ssh_keys\n"
ssh-keygen -t rsa -N "" -f ${BASE_DIR}/ssh_keys/cassandra-key

echo -e "\n-> Creating instances with Terraform..."

# Deploy instances with Terraform
cd ${CASSANDRA_DIR}/terraform

${TERRAFORM} init
${TERRAFORM} plan
${TERRAFORM} apply -auto-approve

if [ ! $? -eq 0 ]; then
	echo -e "\nTerraform apply failed. Check messages to fix problems.\n"
	exit 1
fi

sleep 20

echo -e "\n-> Installing Cassandra using Ansible...\n"

# Install Kafka on instances
cd ${CASSANDRA_DIR}/ansible

ansible-playbook all.yml

if [ $? -eq 0 ]; then
	cat ssh_config >> ${BASE_DIR}/ssh_config
  mv readDB.py  ${CASSANDRA_DIR}/
	echo -e "\nInstallion completed! You can access your machines with ssh -F ssh_config <host-name>"
else
	echo -e "\nInstallion failed. Check messages to fix problems.\n"
  exit 1
fi

cd ${BASE_DIR}

# Start python script on control-center
echo -e "\n-> Creating structure for Cassandra DB...\n"

ssh -f -F ssh_config cassandra-seed-01 'python3 -u createDB.py > create_db.log &'

exit 0