# locals cluster_addons

locals {
  # EKS Auto Mode provides compute autoscaling, pod networking (vpc-cni, kube-proxy),
  # cluster DNS (coredns), EBS storage, load balancing, and the pod identity agent
  # as built-in core components, so no EKS addons are required.
  cluster_addons = {
  }
}
