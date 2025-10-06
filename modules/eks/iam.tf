data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
  tags = {
    Name = "${var.cluster_name}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

data "aws_iam_policy_document" "eks_worker_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_worker_role" {
  name               = "${var.cluster_name}-eks-worker-role"
  assume_role_policy = data.aws_iam_policy_document.eks_worker_assume_role_policy.json
  
  lifecycle {
    ignore_changes = [managed_policy_arns]
  }
  
  tags = {
    Name = "${var.cluster_name}-eks-worker-role"
  }
}
resource "aws_iam_policy" "eks_worker_ebs_policy" {
  name = "eks_worker_ebs_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumeAttribute",
          "ec2:CreateTags"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_policy_attach" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = aws_iam_policy.eks_worker_ebs_policy.arn
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# 
resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEFSDriverpolicy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonSSMpolicy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi-driver-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "pods.eks.amazonaws.com" },
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi.arn
  depends_on      = [aws_iam_role.ebs_csi, aws_eks_cluster.cluster]
}

resource "aws_iam_instance_profile" "karpenter_instance_profile" {
  name = "KarpenterInstanceProfile"
  role = aws_iam_role.eks_worker_role.id
}

resource "aws_iam_role_policy" "ecr_public_access" {
  name = "ecr-public-access-policy"
  role = aws_iam_role.eks_worker_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr-public:GetAuthorizationToken"
        Resource = "*"
      },
    ]
  })
}

# KEDA SQS Access Policy for Worker Nodes
# This allows KEDA Operator to query SQS queues when using node IAM role
# Note: This is a fallback. Prefer using IRSA (keda_operator_role) when possible
resource "aws_iam_role_policy" "keda_sqs_access" {
  name = "KEDASQSAccess"
  role = aws_iam_role.eks_worker_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueues"
        ]
        Resource = "arn:aws:sqs:*:*:traffic-tacos-*"
      }
    ]
  })
}

# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# Use existing OIDC provider instead of creating a new one
data "aws_iam_openid_connect_provider" "cluster" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# OpenTelemetry Collector IAM Role for Service Account
data "aws_iam_policy_document" "otel_collector_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.cluster.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:otel-collector:otel-collector-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "otel_collector_role" {
  name               = "${var.cluster_name}-otel-collector-role"
  assume_role_policy = data.aws_iam_policy_document.otel_collector_assume_role_policy.json

  tags = {
    Name = "${var.cluster_name}-otel-collector-role"
  }
}

# OpenTelemetry Collector IAM Policy
resource "aws_iam_policy" "otel_collector_policy" {
  name        = "${var.cluster_name}-otel-collector-policy"
  description = "IAM policy for OpenTelemetry Collector with X-Ray, CloudWatch access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch, EC2, Logs, X-Ray permissions
      {
        Effect = "Allow"
        Action = [
          # CloudWatch Metrics
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          # EC2 Metadata
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          # CloudWatch Logs
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          # AWS X-Ray
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      },
      # Amazon Managed Service for Prometheus (AMP)
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "otel_collector_policy_attachment" {
  role       = aws_iam_role.otel_collector_role.name
  policy_arn = aws_iam_policy.otel_collector_policy.arn
}

# KEDA Operator IAM Role for Service Account
data "aws_iam_policy_document" "keda_operator_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.cluster.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:keda:keda-operator"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "keda_operator_role" {
  name               = "${var.cluster_name}-keda-operator-role"
  assume_role_policy = data.aws_iam_policy_document.keda_operator_assume_role_policy.json

  tags = {
    Name = "${var.cluster_name}-keda-operator-role"
  }
}

# KEDA Operator IAM Policy for SQS Access
resource "aws_iam_policy" "keda_operator_policy" {
  name        = "${var.cluster_name}-keda-operator-policy"
  description = "IAM policy for KEDA Operator to access SQS queues"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueues"
        ]
        Resource = "arn:aws:sqs:*:*:traffic-tacos-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "keda_operator_policy_attachment" {
  role       = aws_iam_role.keda_operator_role.name
  policy_arn = aws_iam_policy.keda_operator_policy.arn
}

