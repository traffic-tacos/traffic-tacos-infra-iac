data "aws_iam_policy_document" "eventbridge_service_policy" {
  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      aws_cloudwatch_event_bus.custom_bus.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.eventbridge_logs.arn}:*"
    ]
  }
}

data "aws_iam_policy_document" "eventbridge_target_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      "arn:aws:sqs:*:*:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      "arn:aws:sns:*:*:*"
    ]
  }

  dynamic "statement" {
    for_each = length(var.dynamodb_table_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem"
      ]
      resources = var.dynamodb_table_arns
    }
  }
}

resource "aws_iam_role" "eventbridge_service_role" {
  name = "${var.name}-eventbridge-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["events.amazonaws.com", "ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
        }
      }
    ]
  })

  tags = {
    Name = "${var.name}-eventbridge-service-role"
  }
}

resource "aws_iam_role" "eventbridge_target_role" {
  name = "${var.name}-eventbridge-target-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name}-eventbridge-target-role"
  }
}

resource "aws_iam_policy" "eventbridge_service_policy" {
  name        = "${var.name}-eventbridge-service-policy"
  description = "EventBridge service policy for publishing events"
  policy      = data.aws_iam_policy_document.eventbridge_service_policy.json

  tags = {
    Name = "${var.name}-eventbridge-service-policy"
  }
}

resource "aws_iam_policy" "eventbridge_target_policy" {
  name        = "${var.name}-eventbridge-target-policy"
  description = "EventBridge policy for invoking targets"
  policy      = data.aws_iam_policy_document.eventbridge_target_policy.json

  tags = {
    Name = "${var.name}-eventbridge-target-policy"
  }
}

resource "aws_iam_role_policy_attachment" "eventbridge_service_policy_attachment" {
  role       = aws_iam_role.eventbridge_service_role.name
  policy_arn = aws_iam_policy.eventbridge_service_policy.arn
}

resource "aws_iam_role_policy_attachment" "eventbridge_target_policy_attachment" {
  role       = aws_iam_role.eventbridge_target_role.name
  policy_arn = aws_iam_policy.eventbridge_target_policy.arn
}

resource "aws_iam_policy" "dlq_access_policy" {
  count = var.enable_dlq ? 1 : 0

  name        = "${var.name}-eventbridge-dlq-policy"
  description = "Policy for EventBridge DLQ access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.dlq[0].arn
      }
    ]
  })

  tags = {
    Name = "${var.name}-eventbridge-dlq-policy"
  }
}

resource "aws_iam_role_policy_attachment" "dlq_policy_attachment" {
  count = var.enable_dlq ? 1 : 0

  role       = aws_iam_role.eventbridge_target_role.name
  policy_arn = aws_iam_policy.dlq_access_policy[0].arn
}