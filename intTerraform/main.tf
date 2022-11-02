provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "us-east-1"
  
}

 # EC2
resource "aws_instance" "web_server01" {
  ami = "ami-08c40ec9ead489470"
  instance_type = "t2.micro"
  key_name = "dep1-key"
  vpc_security_group_ids = [aws_security_group.web_ssh.id]
  subnet_id              = aws_subnet.subnet1.id

  user_data = "${file("deploy.sh")}"

  tags = {
    "Name" : "Webserver001"
  }
  
}

output "instance_ip" {
  value = aws_instance.web_server01.public_ip
  
}

# VPC
resource "aws_vpc" "my-vpc" {
  cidr_block           = "172.33.0.0/16" #tyrones had 19 instead of 33, shouldn't matter tho?
  enable_dns_hostnames = "true"
 
  tags = {
    "Name" : "deployment4-vpc"
  }
}
 
 
# ELASTIC IP - this service cost money on AWS lol 
resource "aws_eip" "nat_eip_prob" {
  vpc = true
 
}
 
# NAT GATEWAY
resource "aws_nat_gateway" "nat_gateway_prob" {
  allocation_id = aws_eip.nat_eip_prob.id
  subnet_id     = aws_subnet.subnet1.id
}
 
 
# SUBNET 1 (PUBLIC)
resource "aws_subnet" "subnet1" {
  cidr_block              = "172.33.0.0/18"
  vpc_id                  = aws_vpc.my-vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]
}
 
# SUBNET 2 (PRIVATE)
resource "aws_subnet" "pri_subnet1" {
  cidr_block              = "172.33.128.0/18"
  vpc_id                  = aws_vpc.my-vpc.id
  map_public_ip_on_launch = "false"
  availability_zone       = data.aws_availability_zones.available.names[0]
}
 
# INTERNET GATEWAY
resource "aws_internet_gateway" "gw_1" {
  vpc_id = aws_vpc.my-vpc.id
}
 
# ROUTE TABLE
resource "aws_route_table" "route_table1" {
  vpc_id = aws_vpc.my-vpc.id
 
  route {
    cidr_block = "0.0.0.0/0" #cidr_block is for destinations
    gateway_id = aws_internet_gateway.gw_1.id 
  }
}
 
resource "aws_route_table_association" "route-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route_table1.id
}
 
# PRIVATE ROUTE TABLE
resource "aws_route_table" "route_table2" {
  vpc_id = aws_vpc.my-vpc.id
 
  route {
    cidr_block     = "0.0.0.0/0" #0.0.0.0/0 
    nat_gateway_id = aws_nat_gateway.nat_gateway_prob.id
  }
}
 
resource "aws_route_table_association" "route-subnet2" {
  subnet_id      = aws_subnet.pri_subnet1.id
  route_table_id = aws_route_table.route_table2.id
}
 
 
# DATA
data "aws_availability_zones" "available" {
  state = "available"
}






