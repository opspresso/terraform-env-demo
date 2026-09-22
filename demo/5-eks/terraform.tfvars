region = "ap-northeast-2"

name = "eks-demo" # cluster_name for eks-demo

kubernetes_version = "1.36" # cluster_version for eks-demo

ip_family = "ipv4" # ipv4, ipv6

# EKS 퍼블릭 API 엔드포인트 접근 대역. 운영 환경에서는 사무실/VPN 대역으로 좁힙니다.
endpoint_public_access_cidrs = ["0.0.0.0/0"]
