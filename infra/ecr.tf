resource "aws_ecr_repository" "journal_api" {
  name                 = "journal-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # let `terraform destroy` remove it even when images exist

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.journal_api.repository_url
}