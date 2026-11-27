# Access entry that lets Auto Mode nodes on the custom NodeClasses join the cluster.
# EKS created it when compute_config named the node role for the built-in pools. With no
# built-in pool the cluster has no node role, so Terraform owns the entry and keeps it.

resource "aws_eks_access_entry" "auto_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.eks.node_iam_role_arn
  type          = "EC2"
}

resource "aws_eks_access_policy_association" "auto_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.auto_node.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"

  access_scope {
    type = "cluster"
  }
}
