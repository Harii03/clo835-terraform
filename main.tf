cat > main.tf << 'EOF'
data "aws_vpc" "default" { default = true }

data "aws_subnets" "default_subnets" {
  filter { name = "vpc-id" values = [data.aws_vpc.default.id] }
}

resource "aws_security_group" "web_sg" {
  name   = "clo835-web-sg"
  vpc_id = data.aws_vpc.default.id

  ingress { from_port = 22   to_port = 22   protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 8081 to_port = 8081 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 8082 to_port = 8082 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 8083 to_port = 8083 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0    to_port = 0    protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners = ["137112412989"]
  filter { name = "name" values = ["al2023-ami-*-x86_64"] }
}

resource "aws_instance" "host" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default_subnets.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_pair_name

  user_data = <<-EOT
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOT

  tags = { Name = "clo835-ec2" }
}

output "ec2_public_ip" { value = aws_instance.host.public_ip }
EOF
