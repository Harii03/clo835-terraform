cat > main.tf <<'EOF'
# --- Default VPC & Subnets ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- ECR Repositories ---
resource "aws_ecr_repository" "app" {
  name                 = "clo835-app"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "mysql" {
  name                 = "clo835-mysql"
  image_tag_mutability = "MUTABLE"
}

# --- Security Group (SSH + app ports) ---
resource "aws_security_group" "web_sg" {
  name        = "clo835-web-sg"
  description = "Allow SSH and app ports"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App 8081"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App 8082"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App 8083"
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Amazon Linux 2023 AMI (x86_64) ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- EC2 Instance in default VPC (public subnet) ---
resource "aws_instance" "host" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default_subnets.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = var.key_pair_name

  user_data = <<-EOT
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOT

  tags = {
    Name = "clo835-ec2"
  }
}

# --- Outputs ---
output "ec2_public_ip" {
  value = aws_instance.host.public_ip
}
output "ecr_app_url" {
  value = aws_ecr_repository.app.repository_url
}
output "ecr_mysql_url" {
  value = aws_ecr_repository.mysql.repository_url
}
EOF
