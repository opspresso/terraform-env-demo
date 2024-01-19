#!/bin/bash

# eks post-check

AWS_REGION=$(aws configure get default.region)
CLUSTER_NAME="$(kubectl config current-context)"

echo "# ${AWS_REGION}"
echo "# ${CLUSTER_NAME}"

# coredns
echo
echo "# coredns version: $(kubectl get deploy coredns -n kube-system -o json |
  jq '.spec.template.spec.containers[0].image' -r | cut -d':' -f2)"

echo "# coredns replicas: $(kubectl get deploy coredns -n kube-system -o json |
  jq '.spec.replicas' -r)"

# kube-proxy
echo
echo "# kube-proxy version: $(kubectl get daemonset kube-proxy -n kube-system -o json |
  jq '.spec.template.spec.containers[0].image' -r | cut -d':' -f2)"

# aws-node (vpc-cni)
echo
echo "# aws-node version: $(kubectl get daemonset aws-node -n kube-system -o json |
  jq '.spec.template.spec.containers[0].image' -r | cut -d':' -f2)"

# aws-node (WARM_IP_TARGET)
echo
echo "# WARM_IP_TARGET: "$(kubectl get daemonset aws-node -n kube-system -o json |
  jq '.spec.template.spec.containers[].env[] | select(.name | contains("WARM_IP_TARGET")) | .value' -r)
