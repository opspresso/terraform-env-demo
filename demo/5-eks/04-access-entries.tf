# locals access_entries

locals {
  access_sso_ids = {
    # sso_opspresso = "sso-opspresso_c9c6de2d660a92e8"
  }

  access_entries = {
    for key, value in local.access_sso_ids : key => {
      principal_arn = format("arn:aws:iam::%s:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_%s", local.account_id, value)
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
