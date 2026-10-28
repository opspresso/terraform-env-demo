# 8-agent-knowledge

Agent Knowledge가 원본을 저장하는 비공개 S3 버킷 `agent-knowledge-static`을 정의합니다.
이 root는 EKS 클러스터·Pod Identity association을 만들지 않습니다. Pod 역할
`pod-role--agent-knowledge`는 `../4-role`, association은 `../5-eks`가 만듭니다.
릴리즈용 IAM·ECR은 `../8-agent-studio`가 관리합니다.

| 객체 | prefix |
| --- | --- |
| 문서 원본 | `organizations/*/documents/*` |
| 오디오 원본·전사·요약 | `agent-knowledge/audio/*` |

원본 존재 여부를 확인하는 `HeadObject`는 없는 객체와 접근 거부를 구분해야 합니다. 그래서 전용 버킷에
`ListBucket` 권한도 부여합니다. Studio 버킷과 객체는 변경하지 않습니다. Memory와 Forge는 이 버킷을 사용하지 않습니다.

공개 접근과 TLS가 아닌 요청을 차단하고 AES256 서버 암호화를 사용합니다. 보관 기간은 Agent Knowledge의
원본 만료·정리 작업이 관리합니다. 버킷 수명주기는 완료하지 않은 multipart 업로드만 정리하며 원본·전사·요약을
임의로 만료시키지 않습니다.

```bash
terraform init
terraform plan
terraform apply
```

앱 GitOps는 `S3_BUCKET_NAME=agent-knowledge-static`과 기본 AWS 자격증명 체인을 사용합니다. 정적 AWS 키를
앱 Secret에 넣지 않습니다. 공유 PostgreSQL·SSM 연결 Secret은 앱 배포 구성이 관리합니다.
