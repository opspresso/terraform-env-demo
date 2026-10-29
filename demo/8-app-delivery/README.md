# 8-app-delivery

Argo Workflows의 앱 Delivery가 쓰는 AWS 리소스입니다. 이미지 push 역할과, kro `RdsPostgres`·`ValkeyCache`가 만드는 RDS 인스턴스·ElastiCache Serverless cache의 공유 네트워크 리소스를 관리합니다.
계약은 `agent-platform/docs/APP_DELIVERY.md`와 `agent-platform/docs/DELIVERY_V2.md`에 있습니다.

| 리소스 | 용도 |
| --- | --- |
| IAM `app-delivery-push` | registry 단계가 session tag `delivery-project`로 assume합니다. 그 Project의 ECR repository `projects/<slug>`에만 push할 수 있습니다 |
| DB subnet group `app-delivery-rds` | `RdsPostgres` 인스턴스만 쓰는 VPC intra subnet(`2-vpc`, 인터넷 경로 없음)입니다. 노드·Pod 주소가 없으므로 `RdsPostgres` NetworkPolicy가 이 대역의 5432를 열어도 클러스터의 다른 PostgreSQL에는 닿지 않습니다 |
| Security group `app-delivery-rds` | EKS cluster primary security group(Auto Mode 노드와 Pod)에서 TCP 5432만 허용합니다. 어느 namespace가 접속할지는 클러스터의 NetworkPolicy가 정합니다 |
| Security group `app-delivery-valkey` | `ValkeyCache` cache(intra subnet)의 security group입니다. EKS cluster primary security group에서 TCP 6379만 허용합니다. reader endpoint 포트 6380은 열지 않습니다 |
| DB parameter group `app-delivery-postgres18` | `rds.force_ssl=1`로 TLS 없는 연결을 거부합니다. 앱은 `sslmode=require`로 연결합니다. family는 RDS 기본 major 버전(현재 18)과 같아야 합니다 |

registry 단계의 Pod 역할 `pod-role--app-delivery`(`4-role/policies/app-delivery.json`)는 `projects/*` repository를 만들고
이 역할을 assume합니다. Pod Identity association(namespace `app-delivery`, ServiceAccount `delivery-registry`)은 `5-eks`가 만듭니다.

Serverless cache는 같은 addon의 ACK ElastiCache controller가 만듭니다. 그 역할 `pod-role--ack-elasticache`(`4-role/policies/ack-elasticache.json`)는
식별자 `app-*`의 serverless cache·user·user group과 serverless VPC endpoint 생성만 사용할 수 있습니다.

RDS 인스턴스는 `argocd-env-addons`의 `aws-controllers` addon에 있는 ACK RDS controller가 만듭니다. 그 역할 `pod-role--ack-rds`(`4-role/policies/ack-rds.json`)는
식별자 `app-*`의 PostgreSQL 인스턴스, 이 subnet group·parameter group, 삭제 때의 final snapshot(`snapshot:app-*`)만 사용할 수 있습니다. Pod Identity association(namespace `addon-aws-controllers`,
ServiceAccount `ack-rds-controller`)은 `5-eks`가 만듭니다.

## 적용 순서

trust policy가 `4-role`의 역할을, subnet group·security group 규칙이 `2-vpc`(`intra_subnets` output)·`5-eks`의 remote state를 참조합니다.
`2-vpc` → `4-role` → `5-eks` 적용 뒤에 이 디렉터리를 적용합니다.

```bash
terraform init
terraform plan
terraform apply
```

적용 뒤 security group ID를 `argocd-env-addons`의 `env/eks-demo.yaml` `delivery_resources.rds.security_group_id`에 넣습니다.
parameter group 이름(`rds_parameter_group_name`)은 같은 파일의 `delivery_resources.rds.parameter_group`과 같아야 합니다.
이 값이 있어야 `rds-postgres` ResourceGraphDefinition이 렌더됩니다.

```bash
terraform output -raw rds_security_group_id
terraform output -raw valkey_security_group_id   # delivery_resources.valkey.security_group_id
terraform output -json intra_subnet_ids          # delivery_resources.valkey.subnet_ids (순서 유지)
```

`valkey_security_group_id`가 있어야 `valkey-cache` ResourceGraphDefinition이 렌더됩니다.
