# Address changes from the per-workload file layout. Remove after every installation has applied them.

moved {
  from = kubernetes_manifest.general
  to   = kubernetes_manifest.general_node_pool["arm64"]
}

moved {
  from = kubernetes_manifest.general_amd64
  to   = kubernetes_manifest.general_node_pool["amd64"]
}

moved {
  from = kubernetes_manifest.core_zone
  to   = kubernetes_manifest.core_node_pool
}

moved {
  from = kubernetes_manifest.gha_runner_node_class
  to   = kubernetes_manifest.gha_runners_node_class
}

moved {
  from = kubernetes_manifest.gha_runner_node_pool
  to   = kubernetes_manifest.gha_runners_node_pool
}
