# SDTD
Softwares necessary to run (with version that was used testing)
 - Java 8
 - python v3.7 (with boto)
 - terraform v0.12.12
 - ansible v2.9.4
 - spark v2.4.4 (hadoop2.7)
 - sbt v1.3.7
 - aws v1
 - docker

1) Set environment variables (Use the .examples as base)
  (AWS Credentials)
    - cp env/aws.env.example env/aws.env (and edit the file)
  (API Twitter Credentails)
    - cp env/twitter.env.example env/twitter.env (and edit the file)
  (Dockerhub Credentials)
    - cp env/docker.env.example env/docker.env (and edit the file)

2) Install python requirements on your environment
  - pip install -r requirements.txt

3) Run deploy_cassandra.sh to deploy cassandra cluster
4) Run deploy_kafka.sh to deploy kafka cluster
5) Run deploy_kubernetes.sh to deploy kubernetes cluster with spark on it

6) To destroy instances afterwards, run 
- deploy_cassandra.sh destroy 
- deploy_kafka.sh destroy 
- deploy_kubernetes.sh destroy 