output "ec2_public_ip"  { value = aws_instance.ec2.public_ip }
output "ec2_public_dns" { value = aws_instance.ec2.public_dns }
output "ecr_web_repo"   { value = aws_ecr_repository.webapp.repository_url }
output "ecr_mysql_repo" { value = aws_ecr_repository.mysql.repository_url }
