# Use default VPC and its subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group: SSH + app ports
resource "aws_security_group" "ec2_sg" {
  name        = "clo835-ec2-sg"
  description = "Allow SSH and app ports"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App ports 8081-8083
  dynamic "ingress" {
    for_each = toset([8081, 8082, 8083])
    content {
      description = "app"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
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

# ECR repositories
resource "aws_ecr_repository" "webapp" {
  name                 = "my_app"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "mysql" {
  name                 = "my_db"
  image_tag_mutability = "MUTABLE"
}

# Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  owners      = ["137112412989"] # Amazon
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# EC2 instance in default VPC public subnet
resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default_vpc_subnets.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # IMPORTANT: heredoc without quotes
  user_data = <<-BASH
    #!/usr/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
    echo "export DOCKER_BUILDKIT=1" >> /etc/profile
  BASH

  tags = { Name = "clo835-ec2" }
}
