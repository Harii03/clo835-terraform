output "ec2_public_ip" {
  value = aws_instance.ec2.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.ec2.public_dns
}

output "ecr_app_repo_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_db_repo_url" {
  value = aws_ecr_repository.db.repository_url
}
