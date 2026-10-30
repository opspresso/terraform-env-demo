# 8-agent-runway

Agent Runway의 테넌트 리소스와 Variable에 필요한 AWS 리소스입니다. 서비스 계약은
`agent-platform/docs/DELIVERY_RESOURCES.md`에 있습니다.

| 리소스 | 용도 |
| --- | --- |
| KMS `alias/agent-runway` | SSM `/agent-runway/<cluster>/<project>/<env>/<VARIABLE>` SecureString 암호화 |
| S3 `agent-runway-objects` | `bucket` 리소스의 공유 bucket. prefix `<cluster>/app-<project>-<env>/<name>/` |
| IAM `agent-runway-sandbox-objects` | Runway가 assume해 Sandbox용 단기 credential을 발급 |
| IAM `agent-runway-tenant-objects` | 테넌트 앱의 Pod Identity 역할. 클러스터·namespace session tag로 객체 접근을 제한 |
| IAM `agent-runway-tenant-secrets` | 테넌트 SecretStore가 session tag의 Project·Environment 경로만 읽는 역할 |

`4-role`의 `pod-role--agent-runway`를 먼저 적용하고 이 디렉터리를 적용합니다. `5-eks`는 서비스 계정에
Pod Identity를 연결합니다. kro 전용 bucket은 ACK S3 controller가 관리하며 테넌트 역할은 bucket의 클러스터와
namespace tag를 검증합니다.

```bash
terraform init
terraform plan
terraform apply
```

이름을 옮겨도 기존 Terraform backend key는 유지합니다. 이전 Delivery의 KMS alias·bucket·IAM 역할과 parameter는
전환과 복구를 위해 보존합니다. 기존 key와 bucket은 `prevent_destroy`로 보호하며 테넌트 데이터는 삭제하지 않습니다.
