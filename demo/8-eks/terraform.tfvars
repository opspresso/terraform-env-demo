region = "ap-northeast-2"

name = "eks-demo" # cluster_name for eks-demo

kubernetes_version = "1.35" # cluster_version for eks-demo

ip_family = "ipv4" # ipv4, ipv6

key_name = "bruce-seoul"

self_managed_node_groups = {
  workers = {
    group         = "workers"
    instance_type = "c6i.xlarge"
  }
}
