#!/bin/bash

function aborting() {
  echo "Aborting script."
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

# Load environment variables
source ${BASE_DIR}/env/aws.env
cp ${BASE_DIR}/env/twitter.env ${KAFKA_DIR}/ansible/roles/twitter.environment/templates/.env

# Check if asked to destroy
if [ $1 == "destroy" ]; then
  echo -e "\nDestroying kafka instances..."
  cd ${KAFKA_DIR}/terraform
  terraform destroy -auto-approve
  if [ $? -eq 0 ]; then
  	rm ${KAFKA_DIR}/terraform/*.tfstate* > /dev/null 2>&1
    rm ${KAFKA_DIR}/terraform/.terraform > /dev/null 2>&1
    rm ${BASE_DIR}/SDTD-assembly-1.0.jar > /dev/null 2>&1
    rm ${BASE_DIR}/ssh_keys/kafka-key* > /dev/null 2>&1
    rm ${BASE_DIR}/ssh_config > /dev/null 2>&1
  	echo -e "\nInstances removed!\n"
  	exit 0
  else
    echo -e "\nProblem removing instances.\n"
    exit 1
  fi
fi

# Create folder ssh_keys and delete previous keys (if they existed)
if [ "$(ls -A ${BASE_DIR}/ssh_keys/kafka-key*)" ]; then
  echo -e "\nRemoving old ssh-key..."
  rm ${BASE_DIR}/ssh_keys/kafka-key*
elif [ ! -d ${BASE_DIR}/ssh_keys ]; then
	mkdir ${BASE_DIR}/ssh_keys
fi

# Create ssh keypair on folder ssh_keys
echo -e "\nCreating new ssh key 'kafka-key' on folder ssh_keys\n"
ssh-keygen -t rsa -N "" -f ${BASE_DIR}/ssh_keys/kafka-key

echo -e "\nCreating instances with Terraform..."

# Deploy instances with Terraform
cd ${KAFKA_DIR}/terraform

terraform init
terraform plan
terraform apply -auto-approve

if [ ! $? -eq 0 ]; then
	echo -e "\nTerraform apply failed. Check messages to fix problems."
	exit 1
fi

sleep 20

echo -e "\nInstalling Kafka using Ansible..."

# Install Kafka on instances
cd ${KAFKA_DIR}/ansible

ansible-playbook all.yml

if [ $? -eq 0 ]; then
	mv ssh_config ${BASE_DIR}/
  mv twitter.scala ${BASE_DIR}/
	echo -e "\nInstallion completed! You can access your machines with ssh -F ssh_config <host-name>"
else
	echo -e "\nInstallion failed. Check messages to fix problems."
fi

cd ${BASE_DIR}

echo -e "\nStarting kafka publisher..."

# Start python script on control-center
ssh -f -F ssh_config kafka-control-center-01 'nohup ./twitter-publisher.py &'

echo -e "\nBuilding scala subscriber..."

# Moving scala file created by ansible to good folder to build jar file
cp twitter.scala ${KAFKA_DIR}/twitter/src/main/scala/

cd ${KAFKA_DIR}/twitter

# Build jar file
sbt assembly

if [ $? -eq 0 ]; then
  echo -e "\nJar succesfully built!"
  mv target/scala-2.11/SDTD-assembly-1.0.jar ${BASE_DIR}/
  ./clean-scala.sh
else
  echo -e "\nProblem running sbt assembly.\n"
fi
