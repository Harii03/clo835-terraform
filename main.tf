data "aws_vpc" "default" { default = true }
data "aws_subnets" "default_subnets" {
  filter { name = "vpc-id"; values = [data.aws_vpc.default.id] }
}

resource "aws_ecr_repository" "app"   { name = "clo835-app";   image_tag_mutability = "MUTABLE" }
resource "aws_ecr_repository" "mysql" { name = "clo835-mysql"; image_tag_mutability = "MUTABLE" }

data "aws_iam_policy_document" "ec2_trust" {
  statement { actions = ["sts:AssumeRole"]; principals { type = "Service"; identifiers = ["ec2.amazonaws.com"] } }
}
resource "aws_iam_role" "ec2_role" { name = "clo835-ec2-role"; assume_role_policy = data.aws_iam_policy_document.ec2_trust.json }
resource "aws_iam_role_policy_attachment" "ecr_readonly" { role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" }
resource "aws_iam_role_policy_attachment" "ssm_core" { role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
resource "aws_iam_instance_profile" "ec2_profile" { name = "clo835-ec2-profile"; role = aws_iam_role.ec2_role.name }

resource "aws_security_group" "web_sg" {
  name = "clo835-web-sg"; vpc_id = data.aws_vpc.default.id
  ingress { from_port=22   to_port=22   protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=8081 to_port=8081 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=8082 to_port=8082 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=8083 to_port=8083 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

data "aws_ami" "al2023" {
  most_recent = true; owners = ["137112412989"]
  filter { name = "name"; values = ["al2023-ami-*-x86_64"] }
}

resource "aws_instance" "host" {
  ami = data.aws_ami.al2023.id; instance_type = "t3.micro"
  subnet_id = data.aws_subnets.default_subnets.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name
  key_name = var.key_pair_name
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOF
  tags = { Name = "clo835-ec2" }
}

output "ec2_public_ip" { value = aws_instance.host.public_ip }
output "ecr_app_url"   { value = aws_ecr_repository.app.repository_url }
output "ecr_mysql_url" { value = aws_ecr_repository.mysql.repository_url }
