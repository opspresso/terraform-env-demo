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
  ]
}
