# locals

locals {
  workers = [
    {
      name    = "workers"
      vername = "v2"

      mixed_instances = ["c6i.xlarge", "c5.xlarge"]

      min = 3
      max = 12

      key_name = var.key_name
    },
    # {
    #   name    = "graviton"
    #   vername = "v2"

    #   ami_arch        = "arm64"
    #   mixed_instances = ["c6g.xlarge"]

    #   enable_taints = true

    #   min = 3
    #   max = 12

    #   key_name = var.key_name
    # },
  ]
}
