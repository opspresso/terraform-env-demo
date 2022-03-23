# irsa

locals {
  irsa = [
    {
      service_name    = "aws-ebs-csi-driver"
      namespace       = "addon-aws-ebs-csi-driver"
      service_account = "ebs-csi-controller-sa"
      iam_policy      = file("policies/aws-ebs-csi-driver.json")
    },
    {
      service_name    = "aws-efs-csi-driver"
      namespace       = "addon-aws-efs-csi-driver"
      service_account = "efs-csi-controller-sa"
      iam_policy      = file("policies/aws-efs-csi-driver.json")
    },
    {
      service_name    = "aws-load-balancer-controller"
      namespace       = "addon-aws-load-balancer-controller"
      service_account = "aws-load-balancer-controller"
      iam_policy      = file("policies/aws-load-balancer-controller.json")
    },
    {
      service_name    = "aws-node-termination-handler"
      namespace       = "addon-aws-node-termination-handler"
      service_account = "aws-node-termination-handler"
      iam_policy      = file("policies/aws-node-termination-handler.json")
    },
    {
      service_name    = "cluster-autoscaler"
      namespace       = "addon-cluster-autoscaler"
      service_account = "cluster-autoscaler"
      iam_policy      = file("policies/cluster-autoscaler.json")
    },
    {
      service_name    = "external-dns"
      namespace       = "addon-external-dns"
      service_account = "external-dns"
      iam_policy      = file("policies/external-dns.json")
    },
    {
      service_name    = "external-secrets"
      namespace       = "addon-external-secrets"
      service_account = "external-secrets"
      iam_policy      = file("policies/external-secrets.json")
    },
    {
      service_name    = "irsa-operator"
      namespace       = "addon-irsa-operator"
      service_account = "irsa-operator"
      iam_policy      = file("policies/irsa-operator.json")
    },
    {
      service_name    = "karpenter"
      namespace       = "addon-karpenter"
      service_account = "karpenter"
      iam_policy      = file("policies/karpenter.json")
    },
  ]
}

module "irsa" {
  source = "nalbam/eks-irsa/aws"
  # version = "0.15.1"

  for_each = {
    for irsa in local.irsa :
    irsa.service_name => irsa
  }

  cluster_name = local.cluster_name
  provider_url = local.provider_url

  service_name    = each.key
  namespace       = try(each.value.namespace, "")
  service_account = try(each.value.service_account, "")
  iam_policy      = each.value.iam_policy
}

output "irsa" {
  value = values(module.irsa).*.role_arn
}
