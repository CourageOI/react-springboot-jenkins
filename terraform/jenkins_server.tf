# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define the VPC and subnet to launch the instance in
resource "aws_vpc" "vpc" {
  cidr_block = "172.31.0.0/20"

  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  cidr_block              = "172.31.0.0/22"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "jenkins-igw"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# Define the security group to allow SSH access
resource "aws_security_group" "ssh_sg" {
  name_prefix = "ssh_sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the EC2 instance with userdata
resource "aws_instance" "jenkins_instance" {
  ami                    = "ami-0557a15b87f6559cf"
  instance_type          = "t2.micro"
  key_name               = "server_login"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]

  tags = {
    Name = "jenkins_instance"
  }
  user_data = file("user_data.sh")
}
