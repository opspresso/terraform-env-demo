# 8-rovr

rovr 샌드박스가 공유하는 패키지·런타임 캐시용 EFS를 정의합니다. 이 root는 EFS CSI 드라이버를 설치하지 않습니다.
드라이버는 `../5-eks`의 managed addon이 설치하고, PV·PVC는 argocd-env-apps `charts/rovr`가 만듭니다.

| 항목 | 값 | 이유 |
| --- | --- | --- |
| 처리량 모드 | Bursting | 읽기·쓰기 GB당 요금이 없습니다 |
| 수명주기 | 30일 뒤 IA, 접근하면 Standard | 오래 쓰지 않은 캐시의 저장 비용을 줄입니다 |
| 백업 | 없음 | 캐시는 다시 내려받을 수 있습니다 |
| access point | uid·gid 1000, `/cache` | 샌드박스 Pod의 실행 사용자와 같습니다 |

`../5-eks` 적용 후 실행합니다.

```bash
terraform init
terraform plan
terraform apply
terraform output
```

출력한 두 ID를 argocd-env-apps `env/eks-demo.yaml`의 `rovr.sandbox.cache`에 넣습니다.

`BurstCreditBalance`가 0에 가까워지면 처리량이 저장 용량에 비례한 기준값으로 내려갑니다. 캐시가 느려지면 이 지표를 먼저 확인합니다.
