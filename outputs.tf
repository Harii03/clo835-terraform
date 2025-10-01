output "ec2_public_ip" {
  value = aws_instance.host.public_ip
}

output "ecr_app_repo_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_db_repo_url" {
  value = aws_ecr_repository.db.repository_url
}
