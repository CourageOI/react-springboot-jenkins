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

variable "ingressports" {
  type    = list(number)
  default = [8080, 22]
}

# Define the security group to allow SSH access
resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins_sg"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.ingressports
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the EC2 instance with userdata
resource "aws_instance" "jenkins_instance" {
  ami                    = "ami-0557a15b87f6559cf"
  instance_type          = "t2.micro"
  key_name               = "server_login"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  user_data              = "${file("user_data.sh")}"
  tags = {
    Name = "jenkins_instance"
  }
}

output "ec2_global_ips" {
  value = ["${aws_instance.jenkins_instance.*.public_ip}"]
}