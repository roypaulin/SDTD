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

CASSANDRA_DIR="${BASE_DIR}/clusters/cassandra"
KAFKA_DIR="${BASE_DIR}/clusters/kafka"
KUBERNETES_DIR="${BASE_DIR}/clusters/kubernetes"
SPARK_DIR="${BASE_DIR}/clusters/spark"

# Check if asked to destroy
case "$1" in
  "all")
      cp ${BASE_DIR}/ssh_config.base ${BASE_DIR}/ssh_config

      echo -e "\nDeploying all clusters...\n"
      ${CASSANDRA_DIR}/deploy_cassandra.sh
      ${KAFKA_DIR}/deploy_kafka.sh
      ${KUBERNETES_DIR}/deploy_kubernetes.sh
      ${SPARK_DIR}/deploy_spark.sh
      ;;
  "cassandra")
      cp ${BASE_DIR}/ssh_config.base ${BASE_DIR}/ssh_config

      echo -e "\nDeploying only cassandra cluster...\n"
      ${CASSANDRA_DIR}/deploy_cassandra.sh
      ;;
  "kafka")
      cp ${BASE_DIR}/ssh_config.base ${BASE_DIR}/ssh_config
      
      echo -e "\nDeploying only kafka cluster...\n"
      ${KAFKA_DIR}/deploy_kafka.sh
      echo "a"
      ;;
  "kubernetes")
      echo -e "\nDeploying only kubernetes cluster...\n"
      ${KUBERNETES_DIR}/deploy_kubernetes.sh
      ;;
  "spark")
      echo -e "\nDeploying only spark cluster...\n"
      ${SPARK_DIR}/deploy_spark.sh
      ;;
  *)
    echo -e "ERROR: Invalid option. Please use one of the following:"
    echo -e "./deploy.sh all"
    echo -e "./deploy.sh cassandra"
    echo -e "./deploy.sh kafka"
    echo -e "./deploy.sh kubernetes"
    echo -e "./deploy.sh spark"
    ;;
esac