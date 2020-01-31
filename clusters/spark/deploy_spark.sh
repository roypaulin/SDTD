#!/bin/bash

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
SPARK_DIR="${BASE_DIR}/clusters/spark"

if [ ! -d ${UTILS_DIR} ]; then
	mkdir ${UTILS_DIR}
fi

echo -e "\n-> SPARK: Checking if needed softwares are installed..."

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

if [ -f ${UTILS_DIR}/spark/bin/spark-submit ]; then
  SPARK_SUBMIT=${UTILS_DIR}/spark/bin/spark-submit
elif [ -x "$(command -v spark-submit)" ]; then
  SPARK_SUBMIT="$(command -v spark-submit)"
else
  echo -e "\nspark not found. Installing spark into folder utils..."

  wget "https://archive.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz"

  tar -xvf spark-2.4.4-bin-hadoop2.7.tgz

  rm spark-2.4.4-bin-hadoop2.7.tgz

  mv spark-2.4.4-bin-hadoop2.7 ${UTILS_DIR}/spark

  chmod +x ${UTILS_DIR}/spark/bin/spark-submit

  export SPARK_HOME=${UTILS_DIR}/spark
  export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/build:$PYTHONPATH
  export PYTHONPATH=$SPARK_HOME/python/lib/py4j-0.10.4-src.zip:$PYTHONPATH

  SPARK_SUBMIT=${UTILS_DIR}/spark/bin/spark-submit
fi

if [ -x "$(command -v ${SPARK_SUBMIT})" ]; then
  echo -e "OK: spark ready to be used!"
else 
  echo -e "\nProblem installing spark.\n"
  rm -rf ${UTILS_DIR}/spark* >/dev/null 2>&1
  exit 1
fi

# Installing sbt (if not already installed)
echo -e "\n-> Checking if sbt is installed..."

if [ -f ${UTILS_DIR}/sbt ]; then
  SBT=${UTILS_DIR}/sbt
elif [ -x "$(command -v sbt)" ]; then
  SBT="$(command -v sbt)"
else
  echo -e "\nsbt not found. Installing sbt into folder utils..."

  wget "https://piccolo.link/sbt-1.3.7.zip"

  unzip sbt-1.3.7.zip -d ${UTILS_DIR}/

  rm sbt-1.3.7.zip

  chmod +x ${UTILS_DIR}/sbt/bin/sbt

  SBT=${UTILS_DIR}/sbt/bin/sbt
fi

if [ -x "$(command -v ${SBT})" ]; then
  echo -e "OK: sbt ready to be used!"
else 
  echo -e "\nProblem installing sbt.\n"
  rm -rf ${UTILS_DIR}/sbt >/dev/null 2>&1
  exit 1
fi

# Load environment variables
source ${BASE_DIR}/env/aws.env

# Check if asked to destroy
if [ "$1" == "destroy" ]; then
  echo -e "\n-> Destroying spark pod..."
  
  rm ${SPARK_DIR}/spark_submit.log > /dev/null 2>&1

  POD_NAME=$(${KUBECTL} get pods | awk '/sdtd-.*-driver/ {print $1}')
  ${KUBECTL} delete pods ${POD_NAME}
  if [ $? -eq 0 ]; then
    echo -e "\nOK: Spark pod destroyed!"
    exit 0
  else
    echo -e "\nProblem removing spark pod.\n"
    exit 1
  fi
fi

cd ${SPARK_DIR}/twitter

# # Build jar file
echo -e "\n-> Generating JAR that will be deployed on spark...\n"

${SBT} assembly

if [ $? -eq 0 ]; then
  echo -e "\nOK: jar succesfully built!"
  mv target/scala-2.11/SDTD-assembly-1.0.jar ${SPARK_DIR}/
  ./clean-scala.sh
else
  echo -e "\nProblem running sbt assembly.\n"
fi

# Deploy spark

echo -e "\n-> Generating Spark's Docker image that will be deployed on kubernetes...\n"

cd ${SPARK_HOME}/kubernetes/dockerfiles/spark/

mv Dockerfile Dockerfile.original

cp ${SPARK_DIR}/templates/Dockerfile Dockerfile
mv ${SPARK_DIR}/SDTD-assembly-1.0.jar .

cd ${SPARK_HOME}

# Load dockerhub environment variables
source ${BASE_DIR}/env/docker.env

echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin

TIMESTAMP="$(date +"%T" | sed "s#:#.#g")"

./bin/docker-image-tool.sh -r ${DOCKER_USERNAME} -t ${TIMESTAMP} build
./bin/docker-image-tool.sh -r ${DOCKER_USERNAME} -t ${TIMESTAMP} push

cd ${SPARK_HOME}/kubernetes/dockerfiles/spark/

mv Dockerfile.original Dockerfile
rm SDTD-assembly-1.0.jar

echo -e "\n-> Creating serviceaccount and role on cluster...\n"

${KUBECTL} create serviceaccount spark

${KUBECTL} create clusterrolebinding spark-role --clusterrole=edit --serviceaccount=default:spark --namespace=default

echo -e "\n-> Deploying spark on kubernetes...\n"

KUBE_MASTER_IP=$(${KUBECTL} cluster-info | awk '/master/ {print $6}' | sed 's/\x1b\[[0-9;]*m//g')

${SPARK_SUBMIT} \
   --master k8s://${KUBE_MASTER_IP}:443 \
   --deploy-mode cluster \
   --class SDTD.TwitterStream \
   --name sdtd \
   --conf spark.executor.instances=3 \
   --conf spark.kubernetes.container.image=${DOCKER_USERNAME}/spark:${TIMESTAMP} \
   --conf spark.kubernetes.namespace=default \
   --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
    local:///opt/spark/jars/SDTD-assembly-1.0.jar &> ${SPARK_DIR}/spark_submit.log &


echo -e "\nSpark job submited! You can check saved hashtags with one of the two:"
echo -e "ssh -f -F ssh_config 'python3 readDB.py'"
echo -e "python clusters/cassandra/readDB.py'\n"

echo -e "\nYou can also check informations about pods with:"
echo -e "\n kubectl get pods"

exit 0
