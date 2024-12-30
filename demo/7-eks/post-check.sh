#!/bin/bash

# eks post-check

AWS_REGION=$(aws configure get default.region)
CLUSTER_NAME="$(kubectl config current-context)"
CLUSTER_VERSION="${1:-$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.version" --output text)}"

echo "# ${AWS_REGION}"
echo "# ${CLUSTER_NAME}"
echo "# ${CLUSTER_VERSION}"

# coredns
echo
echo "# coredns version: $(kubectl get deploy coredns -n kube-system -o json |
  jq '.spec.template.spec.containers[0].image' -r | cut -d':' -f2)"

echo "# coredns latest:  $(aws eks describe-addon-versions --addon-name coredns --kubernetes-version $CLUSTER_VERSION |
  jq '.addons[0].addonVersions[0].addonVersion' -r)"

echo "# coredns replicas: $(kubectl get deploy coredns -n kube-system -o json |
  jq '.spec.replicas' -r)"

# eks-pod-identity-agent
echo
echo "# eks-pod-identity-agent version: $(kubectl get daemonset eks-pod-identity-agent -n kube-system -o json |
  jq '.spec.template.spec.containers[0].image' -r | cut -d':' -f2)"

echo "# eks-pod-identity-agent latest:  $(aws eks describe-addon-versions --addon-name eks-pod-identity-agent --kubernetes-version $CLUSTER_VERSION |
  jq '.addons[0].addonVersions[0].addonVersion' -r)"

# kube-proxy
echo
echo "# kube-proxy version: $(kubectl get daemonset kube-proxy -n kube-system -o json |
  jq '.spec.template.spec.containers[0].image' -r | cut -d':' -f2)"

echo "# kube-proxy latest:  $(aws eks describe-addon-versions --addon-name kube-proxy --kubernetes-version $CLUSTER_VERSION |
  jq '.addons[0].addonVersions[0].addonVersion' -r)"

# vpc-cni (aws-node)
echo
echo "# vpc-cni version: $(kubectl get daemonset aws-node -n kube-system -o json |
  jq '.spec.template.spec.containers[0].image' -r | cut -d':' -f2)"

echo "# vpc-cni latest:  $(aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version $CLUSTER_VERSION |
  jq '.addons[0].addonVersions[0].addonVersion' -r)"

# aws-node (WARM_IP_TARGET)
echo
echo "# WARM_IP_TARGET: "$(kubectl get daemonset aws-node -n kube-system -o json |
  jq '.spec.template.spec.containers[].env[] | select(.name | contains("WARM_IP_TARGET")) | .value' -r)
