# save ssm

resource "aws_ssm_parameter" "cluster_oidc_url" {
  name  = format("/k8s/common/%s/cluster_oidc_url", var.cluster_name)
  type  = "String"
  value = module.eks.cluster_oidc_issuer_url
}

# resource "aws_ssm_parameter" "cluster_role_name" {
#   name  = format("/k8s/common/%s/cluster_role_name", var.cluster_name)
#   type  = "String"
#   value = module.eks.cluster_role_name
# }

# resource "aws_ssm_parameter" "cluster_version" {
#   name  = format("/k8s/common/%s/cluster_version", var.cluster_name)
#   type  = "String"
#   value = module.eks.cluster_version
# }
