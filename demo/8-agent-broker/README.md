# 8-agent-broker

Agent Broker가 테넌트 리소스와 Variable을 관리하는 데 쓰는 AWS 리소스입니다.
서비스 계약은 `agent-platform/docs/RESOURCE_BROKER.md`에 있습니다.

| 리소스 | 용도 |
| --- | --- |
| KMS `alias/agent-broker` | SSM `/agent-broker/<cluster>/<project>/<env>/<VARIABLE>` SecureString 암호화 |
| S3 `agent-broker-objects` | `bucket` 리소스의 공유 bucket. prefix `<cluster>/app-<project>-<env>/<name>/` |
| IAM `agent-broker-sandbox-objects` | Broker가 assume해 Sandbox용 1시간 credential을 발급. session policy로 prefix 하나만 허용 |
| IAM `agent-broker-tenant-objects` | 배포된 테넌트 앱의 Pod Identity 역할. session tag로 자기 namespace prefix만 허용 |
| IAM `agent-broker-tenant-secrets` | 테넌트 SecretStore가 External Secrets 역할에서 assume. tag의 Project·Environment 경로만 읽음 |

Broker Pod 역할 `pod-role--agent-broker`(`4-role/policies/agent-broker.json`)와 Pod Identity association(`5-eks`)은
다른 디렉터리가 만듭니다. trust policy가 그 역할을 참조하므로 `4-role` 적용 뒤에 이 디렉터리를 적용합니다.

```bash
terraform init
terraform plan
terraform apply
```

KMS key와 bucket은 `prevent_destroy`로 보호합니다. 테넌트 Variable과 객체가 남아 있으면 삭제하지 않습니다.
