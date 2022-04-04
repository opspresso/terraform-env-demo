# addons

# aws eks describe-addon-versions | jq .
# aws eks describe-addon-versions | jq '.addons[] | select(.addonName=="kube-proxy") | .addonVersions[].addonVersion' -r | sort -V -r | head -1
# aws eks describe-addon-versions | jq '.addons[] | select(.addonName=="coredns") | .addonVersions[].addonVersion' -r | sort -V -r | head -1
# aws eks describe-addon-versions | jq '.addons[] | select(.addonName=="vpc-cni") | .addonVersions[].addonVersion' -r | sort -V -r | head -1

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = local.cluster_name
  addon_name   = "kube-proxy"
  # addon_version = "v1.21.2-eksbuild.2"

  # depends_on = [
  #   module.workers-v1.worker_asg_id
  # ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = local.cluster_name
  addon_name   = "coredns"
  # addon_version = "v1.8.7-eksbuild.1"

  # depends_on = [
  #   module.workers-v1.worker_asg_id
  # ]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = local.cluster_name
  addon_name   = "vpc-cni"
  # addon_version = "v1.10.2-eksbuild.1"

  # depends_on = [
  #   module.workers-v1.worker_asg_id
  # ]
}
