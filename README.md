# terraform-env-demo

AWS 데모 환경의 공통 인프라(VPC, ALB, EKS, 기본 노드, addon 공통 IAM)를 관리합니다. `demo/`의 각 디렉터리를 따로 적용합니다.

## 구성

| 디렉터리 | 용도 |
| --- | --- |
| [2-vpc](demo/2-vpc/) | VPC와 subnet |
| [3-alb](demo/3-alb/) | public/internal ALB와 DNS |
| [4-role](demo/4-role/) | addon 공통 Pod Identity 역할(external-dns, external-secrets, atlantis, ACK)과 GitHub Actions OIDC provider |
| [5-eks](demo/5-eks/) | EKS Auto Mode 클러스터 |
| [6-eks-node](demo/6-eks-node/) | Graviton(arm64) AZ별 on-demand 중요 서비스 노드(`core-2a`·`core-2c` 각 1개), AZ별 Spot 기준 노드(2a·2c 각 2개), 증가분 dynamic pool, amd64 앱용 dynamic pool, GitHub Actions runner pool |

EKS 적용 순서: `2-vpc` → `3-alb`·`4-role` → `5-eks` → `6-eks-node`.
opspresso 전용 리소스는 [terraform-env-opsp](https://github.com/opspresso/terraform-env-opsp)가 관리합니다. 서비스 Pod Identity 역할과 association, 전용 NodePool(Workspace, rovr sandbox, Agent Runway amd64 build, Agent PostgreSQL), `opspresso.com` 메일, 보관용 k3s 코드가 여기에 해당합니다.

`6-eks-node`의 NodePool은 `general-amd64`를 빼고 모두 Graviton(arm64, m·r 7세대 이상)이다. 내장 `system` pool의 노드 구성은 EKS Auto Mode가 정한다. 서비스 이미지는 `linux/arm64`로
게시한다. 5-eks는 내장 `general-purpose` pool을 켜지 않고 `system` pool만 사용한다.

Agent Runway에서 architecture `amd64`를 고른 앱 Pod는 dynamic `general-amd64` NodePool의 amd64 large(2 vCPU, c·m·r 7세대 이상)
Spot 노드에서 실행한다(`general_amd64_max_cpu`, 기본 16 vCPU). 노드에는 taint `opspresso.com/arch=amd64:NoSchedule`가 있고,
`argocd-env-projects`의 `app-deploy`가 그 앱 Pod에만 toleration과 nodeSelector `kubernetes.io/arch=amd64`를 쓴다.
그런 앱이 없으면 노드가 없고, 노드가 비면 5분 뒤 회수한다.

재시작이 작업을 끊는 중요 서비스는 AZ별 `core-2a`·`core-2c` NodePool의 on-demand large(2 vCPU, m 8Gi) 노드 2개(AZ마다 1개)에서 실행한다.
대상은 공유 Agent PostgreSQL, 로그인 경로(LLDAP·Dex), Istio ingress·istiod, Agent 서비스(Studio·Memory·Models·Runway·Forge·Knowledge)와 rovr다.
Spot 회수는 2분 예고 뒤 같은 AZ의 노드 여러 대를 한꺼번에 가져가기도 하므로, 이 서비스는 Spot 복제본을 늘리는 대신 on-demand에 둔다.
노드에는 label과 taint `opspresso.com/tier=core`가 있다. Pod는 toleration과 node affinity로 들어온다.
복제본이 하나인 stateful 서비스(PostgreSQL·LLDAP)는 required affinity를 쓴다. EBS volume이 `ap-northeast-2c`에 있으므로 `core-2c`에서 실행된다.
복제본이 여럿인 서비스는 preferred affinity와 zone topology spread를 쓴다. 기본 복제본은 AZ마다 core에 놓이고, HPA 증가분과 rollout surge는 Spot으로 넘친다.
core requests 합계는 약 0.8 vCPU·6.1Gi(DaemonSet 포함, 2026-11-11 측정)로 두 노드 allocatable(각 1780m·7.0Gi)의 절반 이하다.
AMI drift에 따른 core 노드 교체는 03:00–05:00 KST(18:00–20:00 UTC)에만 허용한다. 노드 만료(expireAfter)는 budget과 관계없이 진행된다.

그 밖의 workload는 재시작해도 데이터나 진행 중인 작업을 잃지 않는다(Argo CD, 관측 도구, GitLab, 샘플 앱 등). 이 workload는 AZ별 `baseline-2a`·`baseline-2c` NodePool의 large(2 vCPU, m 8Gi·r 16Gi) Spot 노드 4개(AZ마다 2개,
`auto_mode_baseline_replicas_per_zone=2`)에서 실행한다. 정적 NodePool 하나는 노드를 AZ에 분산하지 않으므로 AZ마다 NodePool을 둔다.
core 밖 requests 합계는 약 3.5 vCPU·18.8Gi(DaemonSet 포함, 2026-11-11 측정)로 m 기준 4대 allocatable(7.1 vCPU·27.5Gi)의 메모리 68%다. AZ마다 노드가 2개이므로 Spot 회수로 한 대가 빠져도
그 AZ에 노드가 남아 EBS PersistentVolume을 쓰는 Pod가 같은 AZ에서 바로 다시 실행된다. 한 AZ의 노드가 모두 빠지면 `general`
NodePool이 같은 AZ에 Spot 노드를 추가한다. 해당 AZ에 맞는 Spot 용량이 없으면 용량이 생길 때까지 EBS 기반 Pod가 대기한다.
rollout surge나 증가분은 dynamic `general` NodePool(`general_max_cpu`, 기본 16 vCPU)이 같은 large 노드를 추가해 처리하고,
비거나 활용도가 낮으면 회수한다. 기준 용량에는 유휴 시간에도 비용이 발생한다.
requests·sidecar·DaemonSet 예약을 합산하고 남은 노드의 allocatable과 비교해 조정한다.

GitHub Actions runner pool(`gha-runners`)은 `argocd-env-addons`의 ARC runner scale set(`charts/arc-runners`)이 쓴다.
전용 `gha-runners` NodeClass는 Workspace와 같은 node 역할·subnet·security group을 쓰지만, image build와 kind가
외부 registry에 접근하도록 `DefaultAllow`이고 Docker 저장소용 200Gi ephemeral disk를 둔다. taint `opspresso.com/gha-runner`로
runner Pod만 받는다. runner Pod 하나는 runner와 dind sidecar를 합쳐 3.5 CPU·14Gi를 요청하므로 8-CPU m·r 노드(32Gi 이상)에 2개씩 배치한다.
한도는 `gha_runner_max_runners=6`에서 노드 4대(CPU 32개·메모리 256Gi)이며 교체용 노드 1대를 포함한다. 이 값은
`charts/arc-runners`의 `maxRunners`와 같게 유지한다. job이 있을 때만 Spot 노드를 만들고(Spot이 부족하면 job이 대기한다), 비면 10분 뒤 회수한다.
runner Pod는 `karpenter.sh/do-not-disrupt`를 달아 통합 회수가 job을 끊지 않는다. Spot 회수는 실행 중인 job을 실패시킨다.

`5-eks`의 `workspace_*` output은 `gha-runners` NodeClass와 terraform-env-opsp가 쓴다.
기존 default NodeClass, PVC, ECR은 변경하지 않는다.
Terraform apply와 실제 장애 주입은 별도 승인 뒤 진행한다.

## Terraform 작성 규칙

`demo/`의 모든 root는 같은 파일 배치와 작성 규칙을 따릅니다. `scripts/check-layout.sh`가 파일 배치를 검사하고, CI가 이 스크립트와 `terraform fmt -check`·`terraform validate`를 실행합니다.

### 파일 이름

파일 이름은 `NN-<주제>.tf`입니다. `NN`은 두 자리 숫자이고, 주제는 소문자·숫자·`-`로 씁니다.

| 파일 | 담는 블록 |
| --- | --- |
| `00-variables.tf` | 모든 `variable`. `variable`이 없는 root에는 두지 않습니다 |
| `02-backend.tf` | `terraform`(`required_version`·`backend`·`required_providers`)과 `provider` |
| `02-remote-state.tf` | `data "terraform_remote_state"` |
| `03-data.tf` | 여러 파일이 함께 쓰는 `data` |
| `03-locals.tf` | 여러 파일이 함께 쓰는 `locals`와 `default_tags`용 `local.tags` |
| `04-`~`98-<주제>.tf` | 주제별 리소스와 그 주제의 `data`·`locals`. 의존 순서대로 번호를 붙이고, 한 주제를 여러 파일로 나누면 같은 번호를 씁니다(예: `32-public-tgs-http.tf`, `32-public-tgs-grpc.tf`) |
| `99-outputs.tf` | 모든 `output` |

각 root에는 `required_version`과 같은 값의 `.terraform-version`을 둡니다.

### 코드

- `required_version`과 provider `version`은 정확한 버전으로 고정합니다(예: `"1.17.1"`, `"6.71.0"`). 범위 지정은 쓰지 않습니다.
- S3 backend는 `encrypt = true`와 `use_lockfile = true`를 씁니다.
- AWS provider는 `default_tags { tags = local.tags }`로 태그를 붙이고, `local.tags`는 `03-locals.tf`에 둡니다.
- `variable`에는 `description`과 `type`을 씁니다.
- 각 root는 `demo` 환경 하나만 배포합니다. 값은 `variable`의 `default`에 두고, 커밋하는 `terraform.tfvars`는 쓰지 않습니다.
- 공개하면 안 되는 값(사무실 IP 대역, 개인 메일 주소 등)은 `default`에 두지 않고 Git이 무시하는 `private.auto.tfvars`로 넘깁니다.
- 바꾸면 backend·remote state와 어긋나거나 리소스가 교체되는 고정값(`region` 등)은 `variable`이 아닌 `03-locals.tf`의 `locals`에 둡니다.
- 파일마다 `locals` 블록은 하나만 둡니다. 본문이 없는 블록은 `data "aws_caller_identity" "current" {}`처럼 한 줄로 씁니다.
- 주석은 코드만으로 알 수 없는 이유·제약·외부 연결을 설명합니다. 파일 이름이나 블록 종류를 반복하는 머리 주석(`# variable`, `# output` 등)은 쓰지 않습니다.
- 파일 이름을 바꾸거나 블록을 다른 파일로 옮겨도 state 주소는 바뀌지 않습니다. 리소스 이름을 바꿀 때는 `moved` 블록을 함께 씁니다.

## 준비

Terraform `1.17.1`, AWS CLI, `jq`, `git`이 필요합니다.

새 backend를 만들 때 저장소 루트에서 실행합니다. AWS profile의 리전은 `ap-northeast-2`로 설정합니다.

```bash
export AWS_PROFILE="your-profile"
aws sts get-caller-identity
aws configure get region
./replace.sh
```

`replace.sh`는 다음을 수행합니다.

- state 저장용 S3 bucket `terraform-workshop-<계정 ID>`를 만들고 public access 차단, 암호화, 버전 관리를 설정합니다. lifecycle 설정이 없으면 이전 state 버전을 90일 뒤 삭제하는 규칙을 추가합니다.
- `demo/2-vpc/02-backend.tf`의 bucket 이름에서 현재 코드의 계정 ID를 읽고, Git이 추적하는 모든 파일에서 그 값을 인증된 계정 ID로 바꿉니다.
- 바꾼 뒤 이전 계정 ID가 남아 있으면 실패합니다. 마지막에 `git diff --stat`으로 바뀐 파일을 보여 줍니다.

### 다른 계정에서 사용

`replace.sh`는 계정 ID만 바꿉니다. 아래 리소스는 계정에 미리 있어야 하거나 변수로 맞춰야 합니다.

| root | 필요한 것 | 맞추는 방법 |
| --- | --- | --- |
| `3-alb` | `domains`의 키인 Route53 public hosted zone. `issued_certificates`에 없는 인증서 도메인(현재 `agrt.dev`)의 ACM 인증서 | `domains`·`primary_domain`·`issued_certificates` 기본값 |
| `4-role` | GitHub Actions OIDC provider | 없으면 `create_github_oidc_provider = true` |
| `5-eks` | 관리자로 등록할 IAM Identity Center permission set | `sso_admin_permission_sets`. 이 계정에 역할이 없는 이름은 건너뛰고, 클러스터 생성자는 항상 관리자입니다 |

모든 root는 `use_lockfile = true`로 S3 state 잠금을 사용합니다. DynamoDB 잠금 테이블은 사용하지 않습니다.
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
