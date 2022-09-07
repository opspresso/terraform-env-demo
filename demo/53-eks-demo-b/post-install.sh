# kubectl apply -f .output/aws_auth.yaml
kubectl set env ds aws-node -n kube-system WARM_IP_TARGET=5
