resource "aws_eks_cluster" "cluster" {
    name = var.cluster_name
    version = var.cluster_version
    role_arn = aws_iam_role.eks_cluster_role.arn

    access_config {
      authentication_mode = "API_AND_CONFIG_MAP"
      bootstrap_cluster_creator_admin_permissions = true
    }

    vpc_config {
      subnet_ids = var.private_subnet_ids
      endpoint_public_access = false
      endpoint_private_access = true
      security_group_ids = [aws_security_group.eks_cluster.id]
    }
    
    zonal_shift_config {
        enabled = false  
    }
    depends_on = [ 
      aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
      aws_iam_role_policy_attachment.eks_service_policy_attachment 
     ]
}

# ---traffic-tacos 계정만 접근---
# resource "aws_eks_access_entry" "user_access" {
#     for_each = toset(var.eks_access_users)
#     cluster_name = aws_eks_cluster.cluster.name
#     principal_arn = "arn:aws:iam::${var.aws_account_id}:user/${each.key}"
#     type = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "user_policy" {
#     for_each = aws_eks_access_entry.user_access
#     cluster_name = each.value.cluster_name
#     principal_arn = each.value.principal_arn
#     policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

#     access_scope {
#       type = "cluster"
#     }
# }

resource "aws_eks_addon" "eks_addons" {
    for_each = { for addon in var.eks_addons : addon.name => addon}
    cluster_name = aws_eks_cluster.cluster.name
    addon_name = each.value.name
    addon_version = each.value.version
    depends_on = [aws_eks_cluster.cluster, aws_eks_node_group.ondemand_node_group, aws_eks_node_group.spot_node_group]
}

resource "aws_launch_template" "ondemand_lt" {
    name = "ondemand_lt"
    instance_type = "t3.large" 
    vpc_security_group_ids = [aws_security_group.eks_node.id,aws_security_group.eks_cluster.id]

    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "ondemand-node"
      }
    }

    block_device_mappings {
        device_name = "/dev/xvda"

        ebs {
        volume_size = var.ondemand_disk_size
        volume_type = "gp3"
        delete_on_termination = true
        encrypted = true
        }
    }

    metadata_options {
        http_endpoint = "enabled"
        http_tokens = "optional"
        http_put_response_hop_limit = 2
    }

    tags = {
        Name = "ondemand_lt"
        "eks:cluster-name" = "tiket-cluster"
        "eks:nodegroup-name" = "ondemand-node-group"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
}

resource "aws_launch_template" "spot_lt" {
    name = "spot_lt-v2"
    vpc_security_group_ids = [aws_security_group.eks_node.id,aws_security_group.eks_cluster.id]
    # image_id = data.aws_ssm_parameter.eks_ami.value
    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "spot-node"
      }
    }

    block_device_mappings {
        device_name = "/dev/xvda"

        ebs {
        volume_size = var.spot_disk_size
        volume_type = "gp3"
        delete_on_termination = false
        encrypted = true
        }
    }

    metadata_options {
        http_endpoint = "enabled"
        http_tokens = "optional"
        http_put_response_hop_limit = 2
    }

    tags = {
        Name = "spot_lt"
        "eks:cluster-name" = "tiket-cluster"
        "eks:nodegroup-name" = "spot-node-group"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
 }

 resource "aws_eks_node_group" "ondemand_node_group" {
    cluster_name = aws_eks_cluster.cluster.name
    node_group_name = "ondemand-node-group"
    node_role_arn = aws_iam_role.eks_worker_role.arn 
    subnet_ids = var.private_subnet_ids
    capacity_type = "ON_DEMAND"
    ami_type = "AL2023_x86_64_STANDARD"

    launch_template {
      id = aws_launch_template.ondemand_lt.id
      version = "$Latest"
    }

    scaling_config {
      desired_size = 1
      min_size = 1
      max_size = 1
    }

    tags = {
      Name = "ondemand-node-group"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
    depends_on = [ aws_launch_template.ondemand_lt,
      aws_iam_role_policy_attachment.eks_worker_policy_attach,
      aws_iam_role_policy_attachment.eks_worker_AmazonEC2ContainerRegistryReadOnly,
      aws_iam_role_policy_attachment.eks_worker_AmazonEKS_CNI_Policy,
      aws_iam_role_policy_attachment.eks_worker_AmazonEKSWorkerNodePolicy ]
}

resource "aws_eks_node_group" "spot_node_group" {
    cluster_name = aws_eks_cluster.cluster.name
    node_group_name = "spot-node-group"
    node_role_arn = aws_iam_role.eks_worker_role.arn
    subnet_ids = var.private_subnet_ids
    capacity_type = "SPOT"
    ami_type = "AL2023_x86_64_STANDARD"

    launch_template {
      id = aws_launch_template.spot_lt.id
      version = "$Latest"
    }

    instance_types = ["t3.large", "t3.medium"]

    scaling_config {
      desired_size = 0
      min_size = 0
      max_size = 2
    }

    tags = {
        Name = "spot-node-group"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"

    }
    depends_on = [ aws_launch_template.spot_lt,
    aws_iam_role_policy_attachment.eks_worker_policy_attach,
    aws_iam_role_policy_attachment.eks_worker_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_worker_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_worker_AmazonEKSWorkerNodePolicy ]
}
