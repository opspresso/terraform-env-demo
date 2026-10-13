# Agent Librio AWS 원본 저장소

향후 EKS의 Librio가 사용할 비공개 S3 버킷 `agent-librio-static`을 정의합니다.
현재 k3s alpha는 MinIO를 사용하므로 이 root를 적용할 필요가 없습니다.
이 root는 EKS 클러스터·노드·Pod Identity association을 만들지 않습니다.
현재 릴리즈용 IAM·ECR 변경은 `../8-agent-studio`에서 별도로 계획하고 적용합니다.

Librio의 문서 원본(`organizations/*/documents/*`)과 오디오 원본·출력
(`agent-librio/audio/*`)만 이 버킷에 저장합니다. 원본 존재 여부를 확인하는
`HeadObject`는 없는 객체와 접근 거부를 구분해야 하므로 전용 버킷에
`ListBucket` 권한도 부여합니다. Studio 버킷과 객체는 변경하지 않습니다.
Memory와 Forge는 이 버킷을 사용하지 않습니다.

공개 접근과 비 TLS 요청을 차단하고 AES256 서버 암호화를 사용합니다.
보관 기간은 Librio의 원본 만료·정리 작업이 관리합니다. 버킷 수명주기는
완료하지 않은 multipart 업로드만 정리하며, 원본·전사·요약을 임의로 만료시키지 않습니다.

미래 EKS를 실제로 준비할 때의 순서입니다. 현재 클러스터 생성 작업은 포함하지 않습니다.

1. `terraform init`, `terraform validate`, `terraform plan`으로 이 root의 새 S3 리소스 5개를 확인합니다.
2. 별도 검토한 plan으로 버킷을 생성한 후 `../4-role`의 `pod-role--agent-librio`를 준비합니다.
3. 향후 별도로 생성하는 EKS는 `../5-eks`의 Librio ServiceAccount association을 사용합니다.
4. 앱 GitOps에서 `S3_BUCKET=agent-librio-static`과 기본 AWS 자격증명 체인을 사용합니다.
   정적 AWS 키를 앱 Secret에 추가하지 않습니다.

공유 PostgreSQL·SSM 연결 Secret은 앱 배포 구성이 관리하며 이 root의 책임이 아닙니다.
