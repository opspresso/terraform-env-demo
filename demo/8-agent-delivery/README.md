# 8-agent-delivery

Agent Runway가 테넌트 리소스와 Variable을 관리하는 데 쓰는 AWS 리소스입니다.
서비스 계약은 `agent-platform/docs/DELIVERY_RESOURCES.md`에 있습니다.

| 리소스 | 용도 |
| --- | --- |
| KMS `alias/agent-delivery` | SSM `/agent-delivery/<cluster>/<project>/<env>/<VARIABLE>` SecureString 암호화 |
| S3 `agent-delivery-objects` | `bucket` 리소스의 공유 bucket. prefix `<cluster>/app-<project>-<env>/<name>/` |
| IAM `agent-delivery-sandbox-objects` | Agent Runway가 assume해 Sandbox용 1시간 credential을 발급. session policy로 prefix 하나만 허용 |
| IAM `agent-delivery-tenant-objects` | 배포된 테넌트 앱의 Pod Identity 역할. session tag로 공유 bucket의 자기 namespace prefix와, bucket tag `kubernetes-namespace`가 자기 namespace인 kro `S3Bucket` 전용 bucket(`<cluster>-*`, ABAC)만 허용. TLS 요청만 허용 |
| IAM `agent-delivery-tenant-secrets` | 테넌트 SecretStore가 External Secrets 역할에서 assume. tag의 Project·Environment 경로만 읽음 |

kro `S3Bucket`의 전용 bucket은 `argocd-env-addons` `aws-controllers`의 ACK S3 controller가 만듭니다. 그 역할 `pod-role--ack-s3`(`4-role/policies/ack-s3.json`)는
이름이 `eks-demo-*`인 bucket의 생성·설정·삭제만 할 수 있고 객체는 읽거나 지우지 못합니다.
앱이 전용 bucket을 쓰려면 Agent Runway가 그 namespace의 ServiceAccount `app`에 이 역할의 Pod Identity association을 만들어야 합니다.

Agent Runway Pod 역할 `pod-role--agent-delivery`(`4-role/policies/agent-delivery.json`)와 Pod Identity association(`5-eks`)은
다른 디렉터리가 만듭니다. trust policy가 그 역할을 참조하므로 `4-role` 적용 뒤에 이 디렉터리를 적용합니다.

```bash
terraform init
terraform plan
terraform apply
```

KMS key와 bucket은 `prevent_destroy`로 보호합니다. 테넌트 Variable과 객체가 남아 있으면 삭제하지 않습니다.

## Runway 전환 준비

`alias/agent-runway`는 기존 key를 가리킵니다. `agent-runway-objects`와
`agent-runway-sandbox-objects`, `agent-runway-tenant-objects`, `agent-runway-tenant-secrets` 역할은 새 이름으로 별도 생성합니다.
`4-role`의 `pod-role--agent-runway`를 먼저 적용한 다음 이 디렉터리를 적용합니다. 기존 bucket, key, 역할과 parameter는 유지합니다.
서비스가 새 이름을 사용하기 전에 원본 객체와 parameter를 대상에 보존하고 접근 권한을 검증해야 합니다.
