# terraform-env-demo

AWS 데모 인프라를 관리합니다. `demo/`의 각 디렉터리를 따로 적용합니다.

## 구성

| 디렉터리 | 용도 |
| --- | --- |
| [2-vpc](demo/2-vpc/) | VPC와 subnet |
| [3-alb](demo/3-alb/) | public/internal ALB와 DNS |
| [4-role](demo/4-role/) | 앱에서 사용할 IAM 역할 |
| [5-eks](demo/5-eks/) | EKS Auto Mode 클러스터 |
| [6-eks-node](demo/6-eks-node/) | 기준 노드 2개 유지 |
| [8-agent-studio](demo/8-agent-studio/) | S3, ECR, k3s 서버 |
| [8-comfy-render](demo/8-comfy-render/) | DynamoDB, S3, 작업 큐 |
| [9-tailscale-exit](demo/9-tailscale-exit/README.md) | Tailscale exit node |

EKS 적용 순서: `2-vpc` → `3-alb`·`4-role` → `5-eks` → `6-eks-node`.
`8-agent-studio`는 `4-role` 적용 후 실행합니다.

## 준비

Terraform `1.15.8`, AWS CLI, `jq`가 필요합니다. 다른 계정에서 사용하려면 도메인과 기존 AWS 리소스 참조도 맞춰야 합니다.

새 backend를 만들 때 저장소 루트에서 실행합니다. AWS profile의 리전은 `ap-northeast-2`로 설정합니다.

```bash
export AWS_PROFILE="your-profile"
aws sts get-caller-identity
aws configure get region
./replace.sh
```

`replace.sh`는 state 저장용 S3 bucket을 만들고 코드의 bucket 이름을 변경합니다. 현재 스크립트가 만드는 DynamoDB 잠금 테이블은 사용하지 않습니다.

DynamoDB 없이 `use_lockfile = true`로 S3 잠금을 사용할 수 있습니다. 현재 코드에는 이 설정이 없습니다. [공식 문서](https://developer.hashicorp.com/terraform/language/backend/s3#state-locking)

## 실행

대상 디렉터리에서 실행합니다. 예:

```bash
cd demo/2-vpc
terraform init
terraform plan
terraform apply
terraform output
```

기존 환경에서는 `default` workspace를 사용합니다. 각 구성의 state는 S3에 따로 저장됩니다. 삭제 전에는 `terraform plan -destroy`로 대상을 확인합니다. 앱 데이터와 일부 k3s 리소스는 `prevent_destroy`로 보호합니다.
