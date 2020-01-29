#!/usr/bin/env python

from boto import ec2
import json
import sys
import os

inventory = {"_meta": {"hostvars": {}}, "all": []}

#
# Make boto connection
#

try:
    aws_region = os.environ["AWS_REGION"]
except:
    print("ERROR: The AWS_REGION environment variable must be set")
    sys.exit(1)

# Make the connection to AWS API
try:
    ec2conn = ec2.connect_to_region(aws_region)
except:
    print("ERROR: Unable to connect to AWS")
    sys.exit(1)

# Run through all the instances
reservations = ec2conn.get_all_instances()
instances = [i for r in reservations for i in r.instances]

for i in instances:

    # Check if the host has a name, if not we don't care about it anyways
    try:
        host_name = i.tags["Name"]
    except:
        host_name = False

    try:
        host_type = i.tags["Type"]
    except:
        host_type = False

    if i.state == "running" and host_name and host_type:

        # Check for a public DNS, if non use the private DNS
        if i.dns_name:
            dns = i.dns_name
        else:
            dns = i.private_dns_name

        public_ip = i.ip_address
        private_ip = i.private_ip_address

        try:
            inventory[host_type]['hosts'].append(host_name)
        except:
            inventory[host_type] = {'hosts': []}
            inventory[host_type]['hosts'].append(host_name)

        inventory["_meta"]["hostvars"][host_name] = {}
        inventory["_meta"]["hostvars"][host_name]["ansible_ssh_host"] = dns
        inventory["_meta"]["hostvars"][host_name]["public_ip"] = public_ip
        inventory["_meta"]["hostvars"][host_name]["private_ip"] = private_ip

print(json.dumps(inventory, indent=4))
