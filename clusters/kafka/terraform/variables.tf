variable "aws_region" {
  description = "The AWS region to create things in."
  #default     = "us-east-1"
  default     = "us-east-2"
}

variable "instance_count" {
  type = map(string)

  default = {
    "rest"            = 0
    "connect"         = 0
    "ksql"            = 0
    "schema"          = 0
    "control_center"  = 1
    "broker"          = 3
    "zookeeper"       = 3
  }
}

variable "instance_prefix" {
  default     = "staging"
}

variable "aws_ami" {
  description = "The AWS AMI."
  #default     = "ami-04b9e92b5572fa0d1" # Image us-east-1
  default     = "ami-0d5d9d301c853a04a" # Image us-east-2
}

variable "aws_instance_type" {
  description = "The AWS Instance Type."
  default     = "t2.large"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet"
  default     = "10.0.0.0/24"
}

variable "key_name" {
  description = "Key Pair"
  default     = "kafka-key"
}

variable "key_path" {
  description = "Public Key Path"
  default     = "../../../ssh_keys/kafka-key.pub"
}
