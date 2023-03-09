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
resource "aws_key_pair" "example_key_pair" {
  key_name = "my_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Define the EC2 instance with userdata
resource "aws_instance" "jenkins_instance" {
  ami                    = "ami-0557a15b87f6559cf"
  instance_type          = "t2.micro"
  key_name               = "my_key_pair"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]

  tags = {
    Name = "jenkins_instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update 
              sudo apt install -y docker.io &&
              docker run -p 8080:8080 -p 50000:50000 -d \ 
              -v jenkins_home:/var/jenkins_home \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v $(which docker):/usr/bin/docker jenkins/jenkins:lts
              EOF
}
