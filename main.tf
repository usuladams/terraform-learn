terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  # access_key = "my-access-key"
  # secret_key = "my-secret-key"
  ## profile = "my-profile"
}


variable "subnet_cidr_block" {
    description = "subnet cidr block"
}

variable "vpc_cidr_block" {
    description = "vpc cidr block"
}

variable "env_prefix" { }

variable "av_zone" { }

variable "my_ip" { }

output "ec2" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone =  var.av_zone

  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}


resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

   tags = {
    Name = "${var.env_prefix}-rtb"
  }  
}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

/*resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

   tags = {
    Name = "${var.env_prefix}-main-rtb"
  }  
}*/

resource "aws_security_group" "myapp-sg" {
  name        = "myapp-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    Name = "${var.env_prefix}-sg"
  }  
}



resource "aws_instance" "myapp-server" {
  ami           = "ami-09d3b3274b6c5d4aa" #data.aws_ami.ubuntu.id  
  instance_type = "t2.micro"
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.av_zone
  associate_public_ip_address = true
  key_name = "firstkey"
  user_data = file("entry-script.sh")
               

  tags = {
    Name = "${var.env_prefix}-server"
  }
}