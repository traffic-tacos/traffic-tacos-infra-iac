resource "aws_ecr_repository" "ticket-ecr" {
  name = "docker"

  tags = {
    Name = "tiket-ecr"
  }
}

resource "aws_ecr_lifecycle_policy" "ticket-ecr-lifecycle" {
  repository = aws_ecr_repository.ticket-ecr.name
  policy = jsonencode({
    "rules": [
      {
      "rulePriority": 1,
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
  })
}