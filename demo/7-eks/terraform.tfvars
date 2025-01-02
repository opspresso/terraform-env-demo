region = "ap-northeast-2"

cluster_name    = "eks-demo" # cluster_name for eks-demo
cluster_version = "1.31"     # cluster_version for eks-demo

ip_family = "ipv4" # ipv4, ipv6

key_name = "bruce-seoul"

self_managed_node_groups = {
  workers = {
    group         = "workers"
    instance_type = "c6i.xlarge"
  }
}
