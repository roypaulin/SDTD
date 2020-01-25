provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_key_pair" "default" {
  key_name = "${var.key_name}"
  public_key = "${file("${var.key_path}")}"
}

resource "aws_instance" "rest" {
    count = "${var.instance_count["rest"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-rest-${format("%02d", count.index+1)}"
        Type = "kafka_rest"
        Cluster = "kafka"
    }
}

resource "aws_instance" "connect" {
    count = "${var.instance_count["connect"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}" 
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-connect-${format("%02d", count.index+1)}"
        Type = "kafka_connect"
        Cluster = "kafka"
    }
}

resource "aws_instance" "ksql" {
    count = "${var.instance_count["ksql"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}" 
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-ksql-${format("%02d", count.index+1)}"
        Type = "ksql"
        Cluster = "kafka"
    }
}
resource "aws_instance" "control_center" {
    count = "${var.instance_count["control_center"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-control-center-${format("%02d", count.index+1)}"
        Type = "control_center"
        Cluster = "kafka"
    }
}

resource "aws_instance" "schema" {
    count = "${var.instance_count["schema"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}" 
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-schema-${format("%02d", count.index+1)}"
        Type = "schema_registry"
        Cluster = "kafka"
    }
}

resource "aws_instance" "broker" {
    count = "${var.instance_count["broker"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-broker-${format("%02d", count.index+1)}"
        Type = "kafka_broker"
        Cluster = "kafka"
    }
}

resource "aws_instance" "zookeeper" {
    count = "${var.instance_count["zookeeper"]}"
    ami = "${var.aws_ami}"
    instance_type = "${var.aws_instance_type}" 
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-zookeeper-${format("%02d", count.index+1)}"
        Type = "zookeeper"
        Cluster = "kafka"
    }
}