# Agent Studio 인프라

S3·ECR와 단일 k3s alpha 인스턴스를 관리한다. EKS production 노드 용량은
[`../6-eks-node`](../6-eks-node/)가 소유한다.

## Agent 배포 권한

ECR 저장소는 Studio·Memory·Librio·Forge·Models 다섯 개다. GitHub Actions 역할
`github--<repository>-ecr`은 해당 저장소의 이미지 게시만 허용한다.
Forge 서버와 sandbox 이미지는 같은 `agent-forge` 저장소의 서로 다른 태그를 사용한다.
`ecr:GetAuthorizationToken`만 AWS API 계약에 따라 `Resource="*"`이며,
이미지 작업은 각 저장소 ARN으로 제한한다.

Librio·Forge·Models는 GitHub API가 반환한 immutable subject prefix와 `refs/tags/v*`만 신뢰한다.
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

기존 External Secrets 정책은 `/k8s/*`를 읽으므로 서비스별 DB URL·OIDC client·metrics
SecureString을 위해 node SSM 권한을 더 넓힐 필요가 없다. secret 값 생성·주입은
명시적인 앱 bootstrap 절차가 담당하며 Terraform state에 secret 값을 추가하지 않는다.

## 도메인

Agent 앱은 `studio.agrt.dev`, `memory.agrt.dev`, `librio.agrt.dev`, `forge.agrt.dev`,
`models.agrt.dev`만 사용한다. 이 root는 다섯 A 레코드를 현재 k3s 인스턴스로 연결하고 이전
Studio·Memory `.rovr.dev` 레코드를 제거한다. 비 Agent wildcard와 hosted zone은 유지한다.

`models.agrt.dev`는 GitHub Pages 카탈로그 CNAME에서 Models 서비스의 A 레코드로 바뀐다.
Route 53은 같은 이름의 CNAME과 A를 함께 둘 수 없다. `86-k3s.tf`의 `moved` block이 기존
`aws_route53_record.models_catalog`를 `aws_route53_record.k3s_agrt["models"]`로 옮기므로 plan은
같은 레코드의 in-place 변경(`type` CNAME→A)으로 표시된다. AWS provider 6.60.0은 이 변경을
기존 레코드 DELETE와 새 레코드 CREATE를 담은 하나의 change batch로 보내므로 두 레코드가 동시에
존재하거나 이름이 비는 순간이 없다. 적용 후 GitHub Pages의 `models.agrt.dev` custom domain은
DNS 검증에 실패하므로 Pages 설정에서 custom domain을 제거한다. Models 앱이 준비되기 전에 적용하면
`models.agrt.dev`는 Gateway의 404 또는 TLS 오류를 반환한다.
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

이 브랜치의 plan은 새 Models ECR·lifecycle policy, 게시용 IAM role·policy·attachment,
기존 k3s pull 정책에 Models 저장소 ARN 추가, `models.agrt.dev` 레코드의 CNAME→A in-place 변경이다
(5 add, 2 change, 0 destroy). EC2·볼륨·기존 버킷·ECR 리소스의 삭제·교체나 무관한 설정 변경이 있으면
적용하지 않는다. Plan 파일은 state 내용을 포함할 수 있으므로 공개하거나 커밋하지 않고, 검토한 파일만
적용한다. 이 README의 작업 절차 자체가 apply를 실행하지는 않는다.

OIDC subject 형식은 [GitHub 문서](https://docs.github.com/en/actions/reference/security/oidc)를,
게시 권한은 [AWS ECR 문서](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-push-iam.html)를 따른다.

## k3s 메모리

`k3s_go_memory_limit_mib`는 k3s 서버의 Go 런타임 메모리 목표이며 기본값은 1536MiB다.
프로세스 RSS·Pod의 hard limit이 아니다. 앱과 Workspace가 함께 사용하는 단일 노드에서
Go 힙이 회수 가능한 여유 메모리를 과도하게 유지하지 않도록 한다.

`aws_ssm_association.k3s_resources`가 기존 인스턴스에도 설정을 반영하고 매일 확인한다.
`configure-k3s-resources.sh`는 소유한 systemd·kubelet drop-in만 관리하며, 내용이 바뀔 때만
k3s를 재시작한다. alpha API는 이때 잠시 중단될 수 있다. 인스턴스와 볼륨은 교체하지 않는다.
새 설정에서 readiness가 실패하면 두 설정 파일을 이전 상태로 복원하고 실패 상태를 반환한다.

적용 후 SSM association의 `Success`, node `Ready`, 전체 앱의 health/readiness와 Workspace
실행·취소·복원을 확인한다. 같은 부하에서 k3s RSS·노드 가용 메모리·CPU를 비교한다.
GC CPU가 과도하거나 API 지연이 증가하면 변수를 올리고 다시 적용한다.

## k3s 이미지 캐시

같은 SSM association이 kubelet의 이미지 정리 정책을 적용한다. k3s 1.32 이상과
기본 data directory를 사용하며, 설정 파일은
`/var/lib/rancher/k3s/agent/etc/kubelet.conf.d/30-agent-studio-image-gc.conf`다.

- 디스크 사용률이 70%에 도달하면 미사용 이미지를 오래된 순서로 정리해 60%를 목표로 한다.
- 디스크 사용률과 관계없이 48시간 동안 사용하지 않은 이미지를 정리한다.
- 실행 중인 컨테이너의 이미지는 보존한다. 삭제한 캐시는 다음 실행 때 registry에서 다시 받는다.

빈번한 배포로 이전 이미지의 압축 blob과 압축 해제된 레이어가 함께 누적되는 것을 제한한다.
별도 prune timer를 두지 않고 kubelet이 이미지 수명을 관리한다. PVC·DB·객체 파일은 정리 대상이
아니다. 사용 중인 이미지나 데이터만으로 임계값을 넘으면 이 정책만으로 용량을 확보할 수 없다.
kubelet 재시작은 미사용 시간 추적을 초기화하므로 이후 48시간이 지나야 기간 기준이 작동한다.

적용 후 node의 `/proxy/configz`에서 `imageGCHighThresholdPercent=70`,
`imageGCLowThresholdPercent=60`, `imageMaximumGCAge=48h0m0s`를 확인하고,
`df -h /`, node `DiskPressure`, 앱 readiness를 확인한다.
정책은 [Kubernetes 이미지 정리](https://kubernetes.io/docs/concepts/architecture/garbage-collection/#container-image-lifecycle)와
[K3s kubelet 설정](https://docs.k3s.io/installation/configuration#kubelet-configuration-files)을 따른다.

## k3s 설정 검증

로컬 회귀 검사는 이 디렉터리에서 일회용 root 컨테이너로 실행한다.

```bash
docker run --rm --network none --user 0 -v "$PWD:/src:ro" \
  bash:5.2 bash /src/tests/configure-k3s-resources.sh
```

최초 적용·재적용·이미지 정책의 drift 수정·두 설정 원복·잘못된 입력을 검사하며
운영 호스트를 수정하지 않는다.
