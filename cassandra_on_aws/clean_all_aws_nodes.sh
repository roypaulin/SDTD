#!/bin/bash

running_instance_ids=$(aws ec2 describe-instances \
                        --filter Name=instance-state-name,Values=running \
                        | grep "InstanceId" \
                        | sed 's/.*"InstanceId": "\(.*\)".*/\1/')

for running_instance_id in $running_instance_ids
do
  aws ec2 terminate-instances --instance-ids "${running_instance_id}"
done
echo -e "\nThe EC2 instances have been successfully terminated\n"
