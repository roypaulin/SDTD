provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_key_pair" "default" {
  key_name = "${var.key_name}"
  public_key = "${file("${var.key_path}")}"
}

resource "aws_instance" "seed" {
    count = "${var.instance_count["seed"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.cassandra_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "cassandra-seed-${format("%02d", count.index+1)}"
        Type = "cassandra_seed"
        Cluster = "cassandra"
    }
}

resource "aws_instance" "node" {
    count = "${var.instance_count["node"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}" 
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.cassandra_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "cassandra-node-${format("%02d", count.index+1)}"
        Type = "cassandra_node"
        Cluster = "cassandra"
    }
}
