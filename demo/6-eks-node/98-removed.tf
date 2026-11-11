# terraform-env-opsp demo/7-shared adopted these by import; forget them without deleting the cluster objects.
removed {
  from = kubernetes_manifest.workspace_node_class
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_manifest.workspace_node_pool
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_manifest.rovr_sandbox_node_pool
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_manifest.delivery_amd64_node_pool
  lifecycle {
    destroy = false
  }
}
