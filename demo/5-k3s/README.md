# 5-k3s (보관용)

단일 EC2 k3s 클러스터 `k3s-demo`의 Terraform 코드다. Agent 플랫폼을 EKS(`eks-demo`)로 이전한 뒤
2026-10-27에 인스턴스를 삭제했다. 나중에 다시 만들 때를 위해 코드만 보관하며 **현재 적용하지 않는다.**
state(`backend/demo/k3s-demo/terraform.tfstate`)는 비어 있다.

| 파일 | 내용 |
| --- | --- |
| `86-k3s.tf` | EC2(m6i.xlarge, AL2023, gp3 120Gi), IAM role·instance profile, security group, `*.demo.agrt.dev` 레코드, Pod용 정책 연결 |
| `85-k3s-iam.tf` | ECR pull(`var.ecr_repositories`)·`/k8s/common/*` SSM 읽기 정책 |
| `87-k3s-resources.tf`, `configure-k3s-resources.sh` | k3s Go 메모리 목표·kubelet image GC를 매일 반영하는 SSM association |
| `bootstrap-k3s.sh` | 최초 설치 user_data |

## 다시 만들 때 확인할 것

- EKS가 `*.agrt.dev`(3-alb)와 `*.demo.rovr.dev`(3-alb)를 소유한다. k3s에 연결할 host를 먼저 정한다.
- 노드 role이 Pod용 정책을 IMDS로 모든 Pod에 노출한다(hop limit 2). 테넌트 workload를 올리기 전에 Pod별 IAM을 설계한다.
- 이미지 build runner(`ec2-linux-x64`)는 더 이상 이 호스트에 없다. CI는 Mac runner를 쓴다.

마지막 루트 볼륨 snapshot: `k3s-demo-final`(EC2 snapshot 태그 `Name`).
