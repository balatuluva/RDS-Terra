# not sure to use parameter store or secrets manager?
data "aws_ssm_parameter" "db_user" {
  name = "db_user"
}

data "aws_ssm_parameter" "db_pass" {
  name = "db_pass"
}

data "aws_subnet" "RDS-VPC-Public-Subnet" {
  id = "subnet-0e5122f43ac79a246"
}

data "aws_security_group" "RDS-SG" {
  id = "sg-014fcecd1612ef337"
}