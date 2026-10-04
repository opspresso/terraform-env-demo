# Agent Studio 인프라

S3·ECR와 단일 k3s alpha 인스턴스를 관리한다. EKS production 노드 용량은
[`../6-eks-node`](../6-eks-node/)가 소유한다.

## k3s 메모리

`k3s_go_memory_limit_mib`는 k3s 서버의 Go 런타임 메모리 목표이며 기본값은 1536MiB다.
프로세스 RSS·Pod의 hard limit이 아니다. 앱과 Workspace가 함께 사용하는 8GiB 노드에서
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
