#!/bin/bash

# eks post-install

AWS_REGION=$(aws configure get default.region)
CLUSTER_NAME="$(kubectl config current-context)"

echo "# ${AWS_REGION}"
echo "# ${CLUSTER_NAME}"

# coredns
echo
echo "# coredns version: $(kubectl get deploy coredns -n kube-system -o json | jq '.spec.template.spec.containers[].image' -r | cut -d':' -f2)"

eksctl utils update-coredns --cluster=$CLUSTER_NAME --approve

echo "# coredns version: $(kubectl get deploy coredns -n kube-system -o json | jq '.spec.template.spec.containers[].image' -r | cut -d':' -f2)"

# kube-proxy
echo
echo "# kube-proxy version: $(kubectl get daemonset kube-proxy -n kube-system -o json | jq '.spec.template.spec.containers[].image' -r | cut -d':' -f2)"

eksctl utils update-kube-proxy --cluster=$CLUSTER_NAME --approve

echo "# kube-proxy version: $(kubectl get daemonset kube-proxy -n kube-system -o json | jq '.spec.template.spec.containers[].image' -r | cut -d':' -f2)"

# vpc-cni (aws-node)
echo
echo "# aws-node version: $(kubectl get daemonset aws-node -n kube-system -o json | jq '.spec.template.spec.containers[].image' -r | cut -d':' -f2)"

eksctl utils update-aws-node --cluster=$CLUSTER_NAME --approve

echo "# aws-node version: $(kubectl get daemonset aws-node -n kube-system -o json | jq '.spec.template.spec.containers[].image' -r | cut -d':' -f2)"

# rm runAsNonRoot

kubectl patch daemonset aws-node -n kube-system --type=json \
  -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/securityContext/runAsNonRoot"}]'
