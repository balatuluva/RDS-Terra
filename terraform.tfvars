aws_region = us-east-1
VPC_cidr_block = "192.168.0.0/16"
VPC_Name = RDS-VPC
azs = ["us-east-1a", "us-east-1b"]
RDS-VPC-Public-Subnet = ["192.168.1.0/24", "192.168.2.0/24"]
RDS-VPC-Private-Subnet = ["192.168.10.0/24", "192.168.20.0/24"]
RDS-Public-RT = "0.0.0.0/0"
ingress_service = ["80", "8080", "443", "8443", "22", "3306", "1900", "1443"]