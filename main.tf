# Use the account's Default VPC and (first) public subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group: SSH + app ports 8081-8083 from internet; all egress allowed
resource "aws_security_group" "ec2_sg" {
  name        = "clo835-ec2-sg"
  description = "Allow SSH and app ports"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = toset([8081, 8082, 8083])
    content {
      description = "App Port"
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

# Two ECR repositories
resource "aws_ecr_repository" "app" {
  name                 = "my_app"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "db" {
  name                 = "my_db"
  image_tag_mutability = "MUTABLE"
}

# Latest Amazon Linux 2023 (x86_64) AMI
data "aws_ami" "al2023" {
  owners      = ["137112412989"] # Amazon
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# One t3.micro EC2 in the default VPC's first subnet (has public IP)
resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"          # fallback: "t2.micro" if t3 not allowed in your account
  subnet_id                   = data.aws_subnets.default_vpc_subnets.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # Pre-install Docker (so it’s ready when you SSH later)
  user_data = <<'BASH'
#!/usr/bin/bash
set -e
dnf update -y || yum update -y
dnf install -y docker || yum install -y docker
systemctl enable --now docker || (service docker start && chkconfig docker on)
usermod -aG docker ec2-user || true
echo 'export DOCKER_BUILDKIT=1' >> /etc/profile
BASH

  tags = {
    Name = "clo835-ec2"
  }
}
