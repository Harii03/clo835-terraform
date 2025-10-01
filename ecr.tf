resource "aws_ecr_repository" "app" {
  name                 = "my_app"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "db" {
  name                 = "my_db"
  image_tag_mutability = "MUTABLE"
}
