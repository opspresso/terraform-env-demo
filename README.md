# terraform-env-demo

AWS 데모 인프라를 관리합니다. `demo/`의 각 디렉터리를 따로 적용합니다.

## 구성

| 디렉터리 | 용도 |
| --- | --- |
| [2-vpc](demo/2-vpc/) | VPC와 subnet |
| [3-alb](demo/3-alb/) | public/internal ALB와 DNS |
| [4-role](demo/4-role/) | 앱에서 사용할 IAM 역할 |
| [5-eks](demo/5-eks/) | EKS Auto Mode 클러스터 |
| [6-eks-node](demo/6-eks-node/) | Graviton(arm64) AZ별 기준 노드(2a·2c 각 1개), 증가분 dynamic pool, 제한된 Workspace pool |
| [5-k3s](demo/5-k3s/README.md) | 삭제한 k3s 서버의 보관용 코드. 적용하지 않음 |
| [8-agent-studio](demo/8-agent-studio/README.md) | Studio S3, Agent ECR, GitHub 게시 역할 |
| [8-agent-delivery](demo/8-agent-delivery/README.md) | Agent Delivery KMS key, 공유 bucket, Sandbox·테넌트 IAM 역할 |
| [8-agent-knowledge](demo/8-agent-knowledge/README.md) | Agent Knowledge의 S3 원본 저장소 |
| [8-comfy-render](demo/8-comfy-render/) | DynamoDB, S3, 작업 큐 |
| [8-domain-mail](demo/8-domain-mail/README.md) | Cloudflare 수신 전달과 SES SMTP 발신, 이전 수신 원본 보관 |
| [9-tailscale-exit](demo/9-tailscale-exit/README.md) | Tailscale exit node |

EKS 적용 순서: `2-vpc` → `3-alb`·`4-role` → `5-eks` → `6-eks-node`.
`8-agent-studio`·`8-agent-delivery`는 `4-role` 적용 후 실행합니다.

`eks-demo`의 모든 노드는 Graviton(arm64, m7g 이상)이다. 서비스 이미지는 `linux/amd64`·`linux/arm64`
multi-platform으로 게시한다. 5-eks는 내장 `general-purpose` pool을 켜지 않고 `system` pool만 사용한다.

기본 workload는 AZ별 `baseline-2a`·`baseline-2c` NodePool의 xlarge(4 vCPU·16Gi) 노드 2개에서 실행한다.
정적 NodePool 하나는 노드를 AZ에 분산하지 않으므로 AZ마다 NodePool을 둔다. requests 합계는
약 2.0 vCPU·11.8Gi(앱·addon·sidecar·DaemonSet)이므로 노드 한 대 또는 AZ 하나가 빠져도 남은 한 대(3.77 vCPU·14.3Gi
allocatable)가 수용한다. EBS PersistentVolume은 생성된 AZ에 묶이므로 그 AZ에 노드가 없으면 `general` NodePool이
같은 AZ에 노드를 추가한다.
rollout surge나 증가분은 dynamic `general` NodePool(`general_max_cpu`, 기본 16 vCPU)이 추가 노드로 처리하고,
비거나 활용도가 낮으면 회수한다. 기준 용량에는 유휴 시간에도 비용이 발생한다.
requests·sidecar·DaemonSet 예약을 합산하고 남은 노드의 allocatable과 비교해 조정한다.

Workspace pool은 기존 Auto Mode node 역할과 private subnet·EKS primary security group을 재사용한다.
`workspaces` NodeClass는 암호화된 160Gi ephemeral disk, `DefaultDeny`와 network policy event log를 사용한다.
전용 taint와 `karpenter.sh/nodepool=workspaces`로 앱·DB와 실행 Pod를 분리하고, pool의 총 한도는
`workspace_max_pods=32`에서는 CPU 48개·메모리 192Gi다. 4-CPU 노드당 1-CPU/2Gi 실행 Pod
3개와 kubelet·DaemonSet 여유를 계산하고 교체용 노드 1개를 허용한다. 노드는 수요가 있을 때만
생성한다. namespace quota와 worker 동시성은 `argocd-env-apps`가 소유하며 같은 용량으로 맞춘다.
노드의 이미지 캐시는 kubelet이 관리하며 Workspace마다 DinD 이미지 사본을 저장하지 않는다.
`argocd-env-addons`의 EKS network policy controller를 먼저 준비한다.

기존 설치는 승인된 `5-eks` 적용으로 Workspace용 output을 state에 기록한 뒤 `6-eks-node`를 적용한다.
기존 default NodeClass, PVC, ECR은 변경하지 않는다.
Terraform apply와 실제 장애 주입은 별도 승인 뒤 진행한다.

## 준비

Terraform `1.17.1`, AWS CLI, `jq`가 필요합니다. 다른 계정에서 사용하려면 도메인과 기존 AWS 리소스 참조도 맞춰야 합니다.

새 backend를 만들 때 저장소 루트에서 실행합니다. AWS profile의 리전은 `ap-northeast-2`로 설정합니다.

```bash
export AWS_PROFILE="your-profile"
aws sts get-caller-identity
aws configure get region
./replace.sh
```

`replace.sh`는 state 저장용 S3 bucket을 만들고 코드의 bucket 이름을 변경합니다. 현재 스크립트가 만드는 DynamoDB 잠금 테이블은 사용하지 않습니다.

`6-eks-node`, `8-agent-studio`, `8-agent-delivery`, `8-agent-knowledge`는 `use_lockfile = true`로 S3 state 잠금을 사용합니다.
실행 역할은 state 객체 외에 같은 key의 `.tflock` 객체를 읽고 쓰고 삭제할 수 있어야 합니다.
[공식 문서](https://developer.hashicorp.com/terraform/language/backend/s3#state-locking)

## 실행

대상 디렉터리에서 실행합니다. 예:

```bash
cd demo/2-vpc
terraform init
terraform plan
terraform apply
terraform output
```

기존 환경에서는 `default` workspace를 사용합니다. 각 구성의 state는 S3에 따로 저장됩니다. 삭제 전에는 `terraform plan -destroy`로 대상을 확인합니다. 앱 데이터(S3·KMS 등)는 `prevent_destroy`로 보호합니다.
