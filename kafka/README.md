# kafka-cluster-infra
Terraform and Ansible to install a Kafka Cluster

Complete instructions available in my Medium Post:

https://medium.com/@mlombog/deploy-a-kafka-cluster-with-terraform-and-ansible-21bee1ee4fb

Softwares necessary to run (with version that was used testing)
 - python3 (with boto)
 - terraform v0.12.12
 - ansible v2.9.4
 - spark v2.4.4 (hadoop2.7)
 - sbt v1.3.7


1) Set environment variables (Use the .examples as base)
	- cp env/aws.env.example env/aws.env (and edit the file)
	- cp env/twitter.env.example env/twitter.env (and edit the file)

2) Install python requirements on your environment
	- pip install -r requirements.txt

2) Run build_kafka.sh to deploy kafka

3) To destroy instances afterwards, run build_kafka.sh destroy 