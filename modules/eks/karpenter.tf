data "aws_iam_policy_document" "karpenter_controller_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "karpenter_controller" {
  name               = "${var.cluster_name}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role.json
  
  tags = {
    Name = "${var.cluster_name}-karpenter-controller"
  }
}


resource "aws_iam_policy" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "KarpenterControllerEC2Permissions"
        Effect = "Allow"
        Action = [
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "pricing:GetProducts",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      },
      {
        Sid = "ConditionalEC2Termination"
        Effect = "Allow"
        Action = "ec2:TerminateInstances"
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid = "PassNodeInstanceRole"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.eks_worker_role.arn
      },
      {
        Sid = "EKSClusterEndpointLookup"
        Effect = "Allow"
        Action = "eks:DescribeCluster"
        Resource = aws_eks_cluster.cluster.arn
      },
      {
        Sid = "KarpenterIAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:ListInstanceProfiles",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile" 
        ]
        Resource = "*"
      },
      {
        Sid = "AllowScopedInstanceProfileCreation"
        Effect = "Allow"
        Action = "iam:CreateInstanceProfile"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid = "AllowScopedInstanceProfileActions"
        Effect = "Allow"
        Action = [
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

# Pod Identity Association for Karpenter
resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = aws_eks_cluster.cluster.name
  namespace       = "karpenter"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller.arn
  
  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_role.karpenter_controller
  ]
}


resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "${var.cluster_name}-karpenter-interruption"
  message_retention_seconds = 300
  
  tags = {
    Name = "${var.cluster_name}-karpenter-interruption"
  }
}



resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "${var.cluster_name}-spot-interruption"
  description = "Spot Instance Interruption Warning"
  
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "spot_interruption" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "instance_state_change" {
  name        = "${var.cluster_name}-instance-state-change"
  description = "EC2 Instance State Change"
  
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "instance_state_change" {
  rule      = aws_cloudwatch_event_rule.instance_state_change.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}


resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [
              aws_cloudwatch_event_rule.spot_interruption.arn,
              aws_cloudwatch_event_rule.instance_state_change.arn
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "karpenter_interruption_queue" {
  name = "${var.cluster_name}-karpenter-interruption-queue"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_interruption_queue" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_interruption_queue.arn
}


resource "aws_iam_role_policy" "worker_node_karpenter" {
  name = "karpenter-node-policy"
  role = aws_iam_role.eks_worker_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}
