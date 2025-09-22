resource "aws_security_group" "eks_node" {
  name   = "${var.cluster_name}-node-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-node-sg"
  }
}

resource "aws_security_group" "eks_cluster" {
  name   = "${var.cluster_name}-cluster-sg"
  vpc_id = var.vpc_id

  tags = {
    Name                                        = "${var.cluster_name}-cluster-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# --- ingress & egress ---
resource "aws_security_group_rule" "node_ingress_kubelet" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node.id
  depends_on               = [aws_eks_cluster.cluster]
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "node_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.eks_node.id

}

resource "aws_security_group_rule" "node_to_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_node.id
}

resource "aws_security_group_rule" "eks_cluster_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_node.id
}

resource "aws_security_group_rule" "eks_cluster_ingress_from_nodes_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_node.id
}

resource "aws_security_group_rule" "eks_node_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_node.id
  cidr_blocks       = ["${var.bastion_host_ip}/32"]
}

resource "aws_security_group_rule" "eks_cluster_bastion" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster.id
  cidr_blocks       = ["${var.bastion_host_ip}/32"]
}