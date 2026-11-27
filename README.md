# terraform-env-demo

AWS 데모 환경의 공통 인프라(VPC, ALB, EKS, 기본 노드, addon 공통 IAM)를 관리합니다. `demo/`의 각 디렉터리를 따로 적용합니다.

## 구성

| 디렉터리 | 용도 |
| --- | --- |
| [2-vpc](demo/2-vpc/) | VPC와 subnet |
| [3-alb](demo/3-alb/) | public/internal ALB와 DNS |
| [4-role](demo/4-role/) | addon 공통 Pod Identity 역할(external-dns, external-secrets, atlantis, ACK)과 GitHub Actions OIDC provider |
| [5-eks](demo/5-eks/) | EKS Auto Mode 클러스터 |
| [6-eks-node](demo/6-eks-node/) | NodePool: Spot `general`(arm64)·`general-amd64`, on-demand 중요 서비스 `core-2c`, GitHub Actions `gha-runners` |

EKS 적용 순서: `2-vpc` → `3-alb`·`4-role` → `5-eks` → `6-eks-node`.
eks-demo는 비용이 우선이다. EKS control plane 로그는 `authenticator`만 CloudWatch에 30일 보관한다(`api`·`audit` 수집 비용이 월 약 $80이었다).
opspresso 전용 리소스는 [terraform-env-opsp](https://github.com/opspresso/terraform-env-opsp)가 관리합니다. 서비스 Pod Identity 역할과 association, 전용 NodePool(Workspace, rovr sandbox, Agent Runway amd64 build, Agent PostgreSQL), `opspresso.com` 메일, 보관용 k3s 코드가 여기에 해당합니다.

NodePool은 NodeClass·taint·구매 방식(on-demand·Spot)·architecture가 다르거나 다른 저장소가 pool 이름을 쓸 때만 나눈다. instance 크기와 노드 수는 나눌 이유가 아니다.
Terraform 파일은 워크로드마다 `NN-<워크로드>.tf` 하나이고, NodeClass(`<워크로드>_node_class`)와 NodePool(`<워크로드>_node_pool`)을 이 순서로 둔다. 공통 값은 `03-locals.tf`에 있다.
[terraform-env-opsp](https://github.com/opspresso/terraform-env-opsp) `7-eks-shared`의 NodePool도 같은 구조다.

| NodePool | 파일 | 용도 | 나눈 이유 |
|---|---|---|---|
| `general` | `50-general.tf` | 전용 pool이 없는 Pod(Argo CD, 관측 도구, GitLab, 샘플·Agent Runway 앱, core 서비스의 HPA 증가분) | 기본 pool, arm64 Spot |
| `general-amd64` | `50-general.tf` | Agent Runway에서 architecture `amd64`를 고른 앱 Pod | architecture, taint `agentops.clush.net/arch=amd64` |
| `core-2c` | `51-core.tf` | 재시작이 작업을 끊는 중요 서비스 | on-demand, taint `opspresso.com/tier=core` |
| `gha-runners` | `52-gha-runners.tf` | GitHub Actions runner | NodeClass(디스크 200Gi), taint `opspresso.com/gha-runner` |

모든 NodePool은 7세대 이상이고 9세대 Graviton(Graviton5)은 제외한다. 이 노드(kernel 6.18.62)에서는 network policy agent의 BPF map 쓰기가 ENOMEM으로 실패해 Pod 통신이 막힌다.
서비스 이미지는 `linux/arm64`로 게시한다. `5-eks`는 EKS 내장 NodePool(`system`, `general-purpose`)을 켜지 않는다. 내장 pool은 수정할 수 없고 `system`은 Graviton5도 고른다.
모든 노드는 `general`·`gha-runners`와 terraform-env-opsp의 NodeClass로 뜨고, 모듈이 만든 Auto Mode 노드 role을 쓴다.
그 role의 EC2 Access Entry(`AmazonEKSAutoNodePolicy`)는 `5-eks/05-auto-node-access.tf`가 관리한다. 없으면 새 노드가 클러스터에 등록되지 않는다.

`general`과 `general-amd64`는 크기별 pool 없이 m·r 2·4·8·16·32 vCPU Spot 중에서(메모리가 병목이라 c는 쓰지 않는다) Karpenter가 대기 중인 Pod에 맞는 가장 싼 instance를 고르고,
비거나 활용도가 낮은 노드는 5분 뒤 통합한다(`general_max_cpu`, 기본 arm64 96·amd64 80 vCPU).
Agent Runway 크기의 Pod는 같은 이름 instance의 vCPU 절반을 요청하므로(4xlarge는 8 CPU·16Gi) 같은 이름의 노드에 들어간다. 8xlarge rollout은 32 vCPU 노드 두 대를 쓴다.
`general-amd64` 노드에는 taint `agentops.clush.net/arch=amd64:NoSchedule`가 있고, `argocd-env-projects`의 `app-deploy`가 그 앱 Pod에만 toleration과 nodeSelector `kubernetes.io/arch=amd64`를 쓴다.
그런 앱이 없으면 노드가 없다.
노드 수는 Pod 수와 요청이 정한다. EKS Auto Mode는 노드당 Pod를 110과 `ENI 수 × (ENI당 IP − 1)` 중 작은 값으로 제한해 large는 27개이고, kubelet `maxPods`로 올릴 수 없다.
Spot 회수로 노드가 빠지면 `general`이 Spot 노드를 추가하고, 그동안 EBS PersistentVolume을 쓰는 Pod는 같은 AZ의 노드를 기다린다.

재시작이 작업을 끊는 중요 서비스는 `core-2c` NodePool의 on-demand large(2 vCPU, m 8Gi) 노드 1개에서 실행한다. eks-demo는 비용이 우선이라 단일 복제본 서비스의 EBS volume이 있는 `ap-northeast-2c`에만 둔다(`core_zones`).
대상은 공유 Agent PostgreSQL, 로그인 경로(LLDAP·Dex), Istio ingress·istiod, Agent 서비스(Studio·Memory·Models·Runway·Forge·Knowledge)와 rovr다.
Spot 회수는 2분 예고 뒤 같은 AZ의 노드 여러 대를 한꺼번에 가져가기도 하므로, 이 서비스는 Spot 복제본을 늘리는 대신 on-demand에 둔다.
노드에는 label과 taint `opspresso.com/tier=core`가 있다. Pod는 toleration과 node affinity로 들어온다.
복제본이 하나인 stateful 서비스(PostgreSQL·LLDAP·Nexus)는 required affinity를 쓴다.
복제본이 여럿인 서비스는 preferred affinity와 zone topology spread를 쓴다. 복제본 하나는 core에 놓이고, 두 번째 복제본·HPA 증가분·rollout surge는 Spot으로 넘친다.
core 노드 하나에는 복제본 서비스마다 하나, stateful 서비스, DaemonSet을 합쳐 Pod 약 20개(상한 27)와 requests 약 4.8Gi(allocatable 6.9Gi)가 놓인다(2026-11-27 측정).
AMI drift에 따른 core 노드 교체는 03:00–05:00 KST(18:00–20:00 UTC)에만 허용한다. 노드 만료(expireAfter)는 budget과 관계없이 진행된다.

GitHub Actions runner pool(`gha-runners`)은 `argocd-env-addons`의 ARC runner scale set(`charts/arc-runners`)이 쓴다.
전용 `gha-runners` NodeClass는 Workspace와 같은 node 역할·subnet·security group을 쓰지만, image build와 kind가
외부 registry에 접근하도록 `DefaultAllow`이고 Docker 저장소용 200Gi ephemeral disk를 둔다. taint `opspresso.com/gha-runner`로
runner Pod만 받는다. runner Pod 하나는 runner와 dind sidecar를 합쳐 2.5 CPU·9Gi를 요청하므로 8-CPU m·r 노드(32Gi 이상)에 3개씩 배치한다.
한도는 `gha_runner_max_runners=6`에서 노드 3대(CPU 24개·메모리 192Gi)이며 교체용 노드 1대를 포함한다. 이 값은
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

### IAM 정책

IAM 정책 문서는 `.tf`에 쓰지 않고 각 root의 `policies/` 아래 JSON 파일로 둡니다. 대상은 IAM 역할의 신뢰 정책(`assume_role_policy`)과 `aws_iam_policy`·`aws_iam_role_policy`·`aws_iam_user_policy`·`aws_iam_group_policy`의 `policy`입니다.

| 파일 | 내용 |
| --- | --- |
| `policies/<이름>.json` | 권한 정책 |
| `policies/trust/<이름>.json` | IAM 역할의 신뢰 정책 |

- 고정된 정책은 `file("${path.module}/policies/<이름>.json")`로 읽습니다.
- 계정 ID·ARN 같은 Terraform 값이 들어가는 정책은 `templatefile()`로 읽습니다. JSON 문자열 안에 `${account_id}` 같은 자리 표시자를 두고, 목록 값은 `${jsonencode(<목록>)}`으로 넣습니다.
- `templatefile()`로 읽는 파일에서는 IAM 정책 변수를 `$${aws:PrincipalTag/...}`처럼 `$$`로 씁니다. `$`가 하나이면 `templatefile()`이 Terraform 식으로 해석해 오류가 납니다.
- JSON에는 주석을 쓸 수 없습니다. 정책의 이유와 제약은 정책 파일을 읽는 리소스 위에 주석으로 씁니다.
- `4-role`은 `policies/*.json` 파일마다 Pod Identity 역할을 만듭니다. 그 역할의 권한 정책이 아닌 파일은 `policies/trust/`처럼 하위 디렉터리에 둡니다.
- `scripts/check-layout.sh`는 `data "aws_iam_policy_document"`와 `file()`·`templatefile()`로 읽지 않은 IAM 정책을 오류로 보고합니다.
- S3 bucket policy 같은 리소스 기반 정책은 이 규칙의 대상이 아닙니다.

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
