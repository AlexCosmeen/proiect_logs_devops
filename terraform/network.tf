resource "aws_vpc" "vpc_test" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "log_app-vpc"
    Environment = "development"
    Project     = "log-app"
  }
}

resource "aws_subnet" "subnet_test" {
  vpc_id            = aws_vpc.vpc_test.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone
}

resource "aws_internet_gateway" "gateway_test" {
  vpc_id = aws_vpc.vpc_test.id

}

resource "aws_route_table" "route_table_test" {
  vpc_id = aws_vpc.vpc_test.id
}

resource "aws_route" "basic_route_test" {
  route_table_id         = aws_route_table.route_table_test.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway_test.id
}

resource "aws_route_table_association" "association_subnet_test" {
  subnet_id      = aws_subnet.subnet_test.id
  route_table_id = aws_route_table.route_table_test.id
}


resource "aws_security_group" "security_group_test_EC2" {
  name        = "SecurityGroup"
  description = "Allow external traffic to port 3000 to post logs on web server and allow ssh connection only to my local machine"
  vpc_id      = aws_vpc.vpc_test.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_test" {
  security_group_id = aws_security_group.security_group_test_EC2.id
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_test" {
  security_group_id = aws_security_group.security_group_test_EC2.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_allowed_cidr //personal ip adress
}

resource "aws_vpc_security_group_egress_rule" "allow_ec2_traffic" {
  security_group_id = aws_security_group.security_group_test_EC2.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
