resource "aws_subnet" "default" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.public_subnet_cidr}"

    map_public_ip_on_launch = false

    tags = {
        Name = "Cassandra Public Subnet"
    }
}