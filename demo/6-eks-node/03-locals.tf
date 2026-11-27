# Values shared by every NodeClass and NodePool in this root.
# Each NN-<workload>.tf file holds one workload: its NodeClass, then its NodePool.
# A workload gets its own pool only when it needs a different NodeClass, a taint, another
# capacity type (on-demand or spot), another architecture or a pool name that another repository uses.
# Size and node count are not reasons: Karpenter fits instance sizes to the pending Pods.

locals {
  # Auto Mode node role, private subnets and cluster security group from 5-eks.
  node_class_spec = {
    role                       = data.terraform_remote_state.eks.outputs.workspace_node_role_name
    subnetSelectorTerms        = [for id in data.terraform_remote_state.eks.outputs.workspace_subnet_ids : { id = id }]
    securityGroupSelectorTerms = [{ id = data.terraform_remote_state.eks.outputs.workspace_security_group_id }]
  }

  # Generation 7 or later. Graviton5 (generation 9) nodes fail eBPF network policy map writes with ENOMEM
  # on the EKS Auto Mode kernel (6.18.62), which blocks Pod traffic.
  node_requirements = [
    { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
    { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
    { key = "eks.amazonaws.com/instance-generation", operator = "NotIn", values = ["9"] },
  ]
}
