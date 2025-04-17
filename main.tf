provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "balaterraformbucket"
    key    = "rds.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "RDS-VPC" {
  cidr_block       = var.VPC_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.VPC_Name
  }
}

resource "aws_internet_gateway" "RDS-IGW" {
  vpc_id = aws_vpc.RDS-VPC.id

  tags = {
    Name = "${var.VPC_Name}-IGW"
  }
}

resource "aws_subnet" "RDS-VPC-Public-Subnet" {
  count = length(var.RDS-VPC-Public-Subnet)
  vpc_id     = aws_vpc.RDS-VPC.id
  cidr_block = element(var.RDS-VPC-Public-Subnet, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.VPC_Name}-Public-Subnet-${count.index+1}"
  }
}

resource "aws_subnet" "RDS-VPC-Private-Subnet" {
  count = length(var.RDS-VPC-Private-Subnet)
  vpc_id     = aws_vpc.RDS-VPC.id
  cidr_block = element(var.RDS-VPC-Private-Subnet, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.VPC_Name}-Private-Subnet-${count.index+1}"
  }
}

resource "aws_route_table" "RDS-Public-RT" {
  vpc_id = aws_vpc.RDS-VPC.id

  route {
    cidr_block = var.RDS-Public-RT
    gateway_id = aws_internet_gateway.RDS-IGW.id
  }

  tags = {
    Name = "${var.VPC_Name}-Public-RT"
  }
}

resource "aws_route_table" "RDS-Private-RT" {
  vpc_id = aws_vpc.RDS-VPC.id

  route = []

  tags = {
    Name = "${var.VPC_Name}-Private-RT"
  }
}

resource "aws_route_table_association" "RDS-Public-RT-Association" {
  count = length(var.RDS-VPC-Public-Subnet)
  subnet_id      = element(aws_subnet.RDS-VPC-Public-Subnet.*.id, count.index)
  route_table_id = aws_route_table.RDS-Public-RT.id
}

resource "aws_route_table_association" "RDS-Private-RT-Association" {
  count = length(var.RDS-VPC-Private-Subnet)
  subnet_id      = element(aws_subnet.RDS-VPC-Private-Subnet.*.id, count.index)
  route_table_id = aws_route_table.RDS-Private-RT.id
}

resource "aws_security_group" "RDS-SG" {
  name        = "${var.VPC_Name}-SG"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.RDS-VPC.id

  dynamic "ingress" {
    for_each = var.ingress_service
    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.VPC_Name}-SG"
  }
}

#resource "aws_nat_gateway" "RDS-NAT" {
#  elastic_ip = ?
#  subnet_id     = aws_subnet.RDS-Public-Subnet.id
#
#  tags = {
#    Name = "RDS-NAT-Gateway"
#  }
#}

#resource "aws_route" "RDS-Private-NAT-Route" {
#  route_table_id         = aws_route_table.RDS-Private-RT.id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.RDS-NAT.id
#}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = ["subnet-0e5122f43ac79a246", "subnet-07475aff794c4dcc0"]

  tags = {
    Name = "${var.VPC_Name}-SubnetGroup"
  }
}

resource "aws_db_instance" "RDS-Mysql" {
  identifier             = "rds"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "8.0"
  username               = aws_secretsmanager_secret_version.db_secret_version.secret_name
  password               = aws_secretsmanager_secret_version.db_secret_version.secret_string
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [data.aws_security_group.RDS-SG.id]
  #parameter_group_name   = aws_db_parameter_group.education.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
