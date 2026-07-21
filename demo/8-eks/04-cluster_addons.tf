# locals cluster_addons

locals {
  # Pin addon versions so unrelated applies do not trigger cluster-wide addon upgrades.
  # Latest versions for each kubernetes_version:
  #   aws eks describe-addon-versions --kubernetes-version <version> --addon-name <addon> \
  #     --query 'addons[0].addonVersions[0].addonVersion'
  cluster_addons = {
    coredns = {
      addon_version = "v1.14.3-eksbuild.3"
    }
    kube-proxy = {
      addon_version = "v1.36.0-eksbuild.13"
    }
    vpc-cni = {
      addon_version  = "v1.22.4-eksbuild.3"
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "3"
        }
      })
    }
    eks-pod-identity-agent = {
      addon_version = "v1.3.10-eksbuild.3"
    }
    # amazon-cloudwatch-observability = {
    #   most_recent = true
    # }
    # aws-ebs-csi-driver = {
    #   most_recent = true
    #   pod_identity_association = [
    #     {
    #       role_arn        = "arn:aws:iam::${local.account_id}:role/pod-role--aws-ebs-csi-driver"
    #       service_account = "ebs-csi-controller-sa"
    #     }
    #   ]
    # }
  }
}
