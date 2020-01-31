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
      echo -e "\nDestroying all clusters...\n"
      ${CASSANDRA_DIR}/deploy_cassandra.sh destroy
      ${KAFKA_DIR}/deploy_kafka.sh destroy
      ${KUBERNETES_DIR}/deploy_kubernetes.sh destroy
      ;;
  "cassandra")
      echo -e "\nDestroying only cassandra cluster...\n"
      ${CASSANDRA_DIR}/deploy_cassandra.sh destroy
      ;;
  "kafka")
      echo -e "\nDestroying only kafka cluster...\n"
      ${KAFKA_DIR}/deploy_kafka.sh destroy
      echo "a"
      ;;
  "kubernetes")
      echo -e "\nDestroying only kubernetes cluster (with or without spark)...\n"
      ${KUBERNETES_DIR}/deploy_kubernetes.sh destroy
      ;;
  "spark")
      echo -e "\nDestroying spark pod...\n"
      ${SPARK_DIR}/deploy_spark.sh destroy
      ;;
  "utils")
      echo -e "\nRemoving utils installed by script...\n"
      rm -rf ${BASE_DIR}/utils
      ;;
  *)
    echo -e "ERROR: Invalid option. Please use one of the following:"
    echo -e "./destroy.sh all"
    echo -e "./destroy.sh cassandra"
    echo -e "./destroy.sh kafka"
    echo -e "./destroy.sh kubernetes"
    echo -e "./destroy.sh spark"
    ;;
esac