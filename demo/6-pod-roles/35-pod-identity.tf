# Pod Identity Association

locals {
  pod_identity_associations = {
    "aws-ebs-csi-controller" = {
      role_name       = "pod-role--aws-ebs-csi-driver"
      namespace       = "addon-aws-ebs-csi-driver"
      service_account = "ebs-csi-controller-sa"
    }
    "aws-ebs-csi-node" = {
      role_name       = "pod-role--aws-ebs-csi-driver"
      namespace       = "addon-aws-ebs-csi-driver"
      service_account = "ebs-csi-node-sa"
    }
    "aws-load-balancer-controller" = {
      role_name       = "pod-role--aws-load-balancer-controller"
      namespace       = "addon-aws-load-balancer-controller"
      service_account = "aws-load-balancer-controller"
    }
    "aws-node-termination-handler" = {
      role_name       = "pod-role--aws-node-termination-handler"
      namespace       = "addon-aws-node-termination-handler"
      service_account = "aws-node-termination-handler"
    }
    "cluster-autoscaler" = {
      role_name       = "pod-role--cluster-autoscaler"
      namespace       = "addon-cluster-autoscaler"
      service_account = "cluster-autoscaler"
    }
    "external-dns" = {
      role_name       = "pod-role--external-dns"
      namespace       = "addon-external-dns"
      service_account = "external-dns"
    }
    "external-secrets" = {
      role_name       = "pod-role--external-secrets"
      namespace       = "addon-external-secrets"
      service_account = "external-secrets"
    }
    "karpenter" = {
      role_name       = "pod-role--karpenter"
      namespace       = "addon-karpenter"
      service_account = "karpenter"
    }
    "kubecost" = {
      role_name       = "pod-role--kubecost"
      namespace       = "addon-kubecost"
      service_account = "kubecost"
    }
  }
}

# output

output "pod_identity_associations" {
  description = "eks pod-identity-associations"
  value       = local.pod_identity_associations
}
