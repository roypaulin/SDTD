
resource "aws_security_group" "cassandra_sg" {
    name = "vpc_cassandra_sg"
    description = "Accept incoming connections."

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH"
    }
    ingress {
        from_port = 9042
        to_port = 9042
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Native Protocol Clients"
    }
    ingress {
        from_port = 7000
        to_port = 7000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Cluster Communication"
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"] 
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags = {
        Name = "cassandra_cluster_sg"
    }
}

