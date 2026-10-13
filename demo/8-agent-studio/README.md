# Agent Studio 인프라

S3·ECR와 단일 k3s alpha 인스턴스를 관리한다. EKS production 노드 용량은
[`../6-eks-node`](../6-eks-node/)가 소유한다.

## Agent 배포 권한

ECR 저장소는 Studio·Memory·Librio·Forge 네 개다. GitHub Actions 역할
`github--<repository>-ecr`은 해당 저장소의 이미지 게시만 허용한다.
Forge 서버와 sandbox 이미지는 같은 `agent-forge` 저장소의 서로 다른 태그를 사용한다.
`ecr:GetAuthorizationToken`만 AWS API 계약에 따라 `Resource="*"`이며,
이미지 작업은 각 저장소 ARN으로 제한한다.

Librio·Forge는 GitHub API가 반환한 immutable subject prefix와 `refs/tags/v*`만 신뢰한다.
`main`, Pull Request, environment subject와 다른 저장소는 허용하지 않는다.
GitHub OIDC의 `aud`는 `sts.amazonaws.com`이어야 한다.
기존 Studio·Memory 역할은 이번 Terraform 인수에서 trust와 권한을 그대로 보존한다.
두 역할에는 이전 이름 형식·immutable 형식과 `main`·`v*` 태그가 이미 허용되어 있다.

기존 Studio의 role·managed policy·attachment와 Memory의 role·inline policy는
`91-github-ecr.tf`의 import block으로 가져온다. Memory inline policy를 managed policy로
전환하거나 잠시 분리하지 않는다. 인수 plan의 기존 IAM 변경은 관리 태그뿐이어야 하며,
기존 ECR·S3·EC2의 재생성이나 권한 변경이 있으면 적용하지 않는다.

신규 S3는 [`../8-agent-librio`](../8-agent-librio/README.md)의 별도 미래 EKS root다.
이 root의 릴리즈 권한 변경을 적용해도 Librio 버킷·EKS 클러스터·노드는 생성하지 않는다.
현재 k3s는 앱 GitOps의 MinIO와 공유 PostgreSQL을 사용한다.

새 앱의 ECR pull Secret은 앱 namespace의 `ECRAuthorizationToken`과 `ExternalSecret`이
관리한다. 기존 node 역할의 ECR 권한으로 충분하며 새 AWS 키를 저장하지 않는다.
`bootstrap-k3s.sh`의 기존 Studio·Memory 갱신기는 최초 설치용이다.
`user_data`가 기존 인스턴스에서 무시되므로 그 파일 변경으로 기존 노드를 갱신할 수 없다.

기존 External Secrets 정책은 `/k8s/*`를 읽으므로 서비스별 DB URL·delegation·metrics
SecureString을 위해 node SSM 권한을 더 넓힐 필요가 없다. secret 값 생성·주입은
명시적인 앱 bootstrap 절차가 담당하며 Terraform state에 secret 값을 추가하지 않는다.

## 도메인

Agent 앱은 `studio.agrt.dev`, `memory.agrt.dev`, `librio.agrt.dev`, `forge.agrt.dev`만 사용한다.
이 root는 네 A 레코드를 현재 k3s 인스턴스로 연결하고 이전 Studio·Memory `.opsp.dev`
레코드를 제거한다. 비 Agent wildcard와 hosted zone은 유지한다.
모델 카탈로그의 기존 `models.opspresso.com` CNAME은 import 후 `models.agrt.dev`로
교체한다. 대상 `opspresso.github.io`와 TTL 300은 유지하고, 새 레코드를 먼저 만든다.
이 변경은 GitHub Pages의 custom domain·저장소 CNAME·카탈로그 소비자 URL 변경과
함께 조율해야 한다. DNS만 바꿔서는 새 HTTPS 주소가 완성되지 않는다.
미래 EKS ALB는 `../3-alb`의 기존 `agrt.dev` ACM 인증서(`*.agrt.dev` 포함)를 SNI로 사용한다.
ALB root는 현재 Agent DNS를 인수하거나 같은 레코드를 중복 관리하지 않는다.
EKS 전환 때 DNS state 소유권과 레코드 대상을 별도 계획으로 함께 이전해야 한다.

## 계획 확인

Terraform `1.15.8`과 AWS provider `6.60.0`을 사용한다. `default` workspace에서 실행한다.

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -input=false -out=terraform.tfplan
```

현재 배포용 plan은 기존 수동 IAM 5개 인수, 신규 게시용 IAM 6개, 신규 `.agrt.dev` DNS 2개,
이전 `.opsp.dev` DNS 2개 제거, 모델 카탈로그 CNAME 인수·교체와 IAM 관리 태그 변경을 포함한다. EC2·볼륨·기존 버킷·ECR
리소스 삭제나 교체는 없어야 한다. plan 파일은 state 내용을 포함할 수 있으므로 공개하거나
커밋하지 않고, 검토한 파일만 적용한다. 이 README의 작업 절차 자체가 apply를 실행하지는 않는다.

OIDC subject 형식은 [GitHub 문서](https://docs.github.com/en/actions/reference/security/oidc)를,
게시 권한은 [AWS ECR 문서](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-push-iam.html)를 따른다.

## k3s 메모리

`k3s_go_memory_limit_mib`는 k3s 서버의 Go 런타임 메모리 목표이며 기본값은 1536MiB다.
프로세스 RSS·Pod의 hard limit이 아니다. 앱과 Workspace가 함께 사용하는 단일 노드에서
Go 힙이 회수 가능한 여유 메모리를 과도하게 유지하지 않도록 한다.

`aws_ssm_association.k3s_resources`가 기존 인스턴스에도 설정을 반영하고 매일 확인한다.
`configure-k3s-resources.sh`는 소유한 systemd drop-in만 관리하며, 내용이 바뀔 때만
k3s를 재시작한다. alpha API는 이때 잠시 중단될 수 있다. 인스턴스와 볼륨은 교체하지 않는다.
새 설정에서 readiness가 실패하면 이전 파일을 복원하고 실패 상태를 반환한다.

적용 후 SSM association의 `Success`, node `Ready`, 전체 앱의 health/readiness와 Workspace
실행·취소·복원을 확인한다. 같은 부하에서 k3s RSS·노드 가용 메모리·CPU를 비교한다.
GC CPU가 과도하거나 API 지연이 증가하면 변수를 올리고 다시 적용한다.

로컬 회귀 검사는 이 디렉터리에서 일회용 root 컨테이너로 실행한다.

```bash
docker run --rm --network none --user 0 -v "$PWD:/src:ro" \
  bash:5.2 bash /src/tests/configure-k3s-resources.sh
```

최초 적용·재적용·이전 설정 원복·잘못된 입력을 검사하며 운영 호스트를 수정하지 않는다.
