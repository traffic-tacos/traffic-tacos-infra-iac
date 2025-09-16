data "aws_iam_policy_document" "dynamodb_access_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem"
    ]
    resources = [
      for table in aws_dynamodb_table.table : table.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      for table in aws_dynamodb_table.table : "${table.arn}/index/*"
    ]
  }
}

data "aws_iam_policy_document" "dynamodb_read_only_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      for table in aws_dynamodb_table.table : table.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      for table in aws_dynamodb_table.table : "${table.arn}/index/*"
    ]
  }
}

resource "aws_iam_role" "dynamodb_application_role" {
  name = "${var.name}-dynamodb-application-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
        }
      }
    ]
  })

  tags = {
    Name = "${var.name}-dynamodb-application-role"
  }
}

resource "aws_iam_role" "dynamodb_readonly_role" {
  name = "${var.name}-dynamodb-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
        }
      }
    ]
  })

  tags = {
    Name = "${var.name}-dynamodb-readonly-role"
  }
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = "${var.name}-dynamodb-access-policy"
  description = "DynamoDB access policy for application"
  policy      = data.aws_iam_policy_document.dynamodb_access_policy.json

  tags = {
    Name = "${var.name}-dynamodb-access-policy"
  }
}

resource "aws_iam_policy" "dynamodb_readonly_policy" {
  name        = "${var.name}-dynamodb-readonly-policy"
  description = "DynamoDB read-only policy"
  policy      = data.aws_iam_policy_document.dynamodb_read_only_policy.json

  tags = {
    Name = "${var.name}-dynamodb-readonly-policy"
  }
}

resource "aws_iam_role_policy_attachment" "dynamodb_application_policy_attachment" {
  role       = aws_iam_role.dynamodb_application_role.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_readonly_policy_attachment" {
  role       = aws_iam_role.dynamodb_readonly_role.name
  policy_arn = aws_iam_policy.dynamodb_readonly_policy.arn
}