#!/bin/bash

# global settings
image_id='ami-0d5d9d301c853a04a'
instance_type='t3.xlarge'
key_name='yoeungm-ec2-rsa'
security_group_id='sg-72f83417'
bootstrap_script='file://bootstrap-script.txt'
ec2_user='ubuntu'
path_to_private_key='~/.ssh/yoeungm-ec2-rsa.pem'

# TODO : don't forget to create a common security group with ssh allowance before
# TODO : don't forget to create a common VPC before
aws ec2 run-instances --image-id $image_id \
											--count 1 \
											--instance-type $instance_type \
											--key-name $key_name \
											--subnet-id subnet-519a7d3a \
											--placement '{"AvailabilityZone":"us-east-2a"}' \
											--security-group-ids $security_group_id \
											--user-data $bootstrap_script
aws ec2 run-instances --image-id $image_id \
											--count 1 \
											--instance-type $instance_type \
											--key-name $key_name \
											--subnet-id subnet-647c211e \
											--placement '{"AvailabilityZone":"us-east-2b"}' \
											--security-group-ids $security_group_id \
											--user-data $bootstrap_script
aws ec2 run-instances --image-id $image_id \
											--count 1 \
											--instance-type t3.xlarge \
											--key-name $key_name \
											--subnet-id subnet-446ce908 \
											--placement '{"AvailabilityZone":"us-east-2c"}' \
											--security-group-ids $security_group_id \
											--user-data $bootstrap_script
echo -e "\nThe 3 EC2 instances have been successfully created\n"
echo -e "\nSleeping until the instances have been totally deployed...\n"

sleep 2m

running_instance_public_ips=$(aws ec2 describe-instances --filter Name=instance-state-name,Values=running | grep "PublicIp" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | uniq)
master_public_ip=$(echo $running_instance_public_ips | cut -d' ' -f 1)
running_instance_private_ips=$(aws ec2 describe-instances --filter Name=instance-state-name,Values=running | grep "PrivateIpAddress" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | uniq)
first_instance_private_ip=$(echo $running_instance_private_ips | cut -d' ' -f 1)
second_instance_private_ip=$(echo $running_instance_private_ips | cut -d' ' -f 2)
seeds="${first_instance_private_ip}, $second_instance_private_ip"	# we are using 2 seeds in the 3 nodes cluster

i=1
for running_instance_public_ip in $running_instance_public_ips
do
	current_instance_private_ip=$(echo $running_instance_private_ips | cut -d' ' -f $i)
	ssh_command="sudo sed -i 's/listen_address: localhost/listen_address: ${current_instance_private_ip}/g' /etc/cassandra/cassandra.yaml"
	ssh -o "StrictHostKeyChecking no" -i ${path_to_private_key} ${ec2_user}@${running_instance_public_ip} ${ssh_command}
	ssh_command="sudo sed -i 's/# broadcast_rpc_address: 1.2.3.4/broadcast_rpc_address: ${current_instance_private_ip}/g' /etc/cassandra/cassandra.yaml"
	ssh -o "StrictHostKeyChecking no" -i ${path_to_private_key} ${ec2_user}@${running_instance_public_ip} ${ssh_command}
	ssh_command="sudo sed -i 's/seeds: \\\"127.0.0.1\\\"/seeds: \\\"${seeds}\\\"/g' /etc/cassandra/cassandra.yaml"
	ssh -o "StrictHostKeyChecking no" -i ${path_to_private_key} ${ec2_user}@${running_instance_public_ip} ${ssh_command}
	# setting $JAVA_HOME is not necessarily required
	ssh_command="echo \"JAVA_HOME=\\\"/usr/lib/jvm/zulu-8-amd64\\\"\" >> ~/.bashrc && source ~/.bashrc"
	ssh -o "StrictHostKeyChecking no" -i ${path_to_private_key} ${ec2_user}@${running_instance_public_ip} ${ssh_command}
	ssh_command="sudo service cassandra start"
	ssh -o "StrictHostKeyChecking no" -i ${path_to_private_key} ${ec2_user}@${running_instance_public_ip} ${ssh_command}
	echo -e "\nCassandra service started on ${running_instance_public_ip}\n"
	((i++))
done

sleep 1m

echo -e "\nThe cassandra cluster has been successfully deployed, here is the cluster status\n"

ssh_command='sudo nodetool status'
ssh -o "StrictHostKeyChecking no" -i ${path_to_private_key} ${ec2_user}@${master_public_ip} ${ssh_command}
