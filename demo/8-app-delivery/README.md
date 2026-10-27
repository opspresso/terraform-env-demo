# 8-app-delivery

Argo Workflows의 앱 Delivery가 이미지를 push할 때 쓰는 AWS 리소스입니다.
계약은 `agent-platform/docs/APP_DELIVERY.md`에 있습니다.

| 리소스 | 용도 |
| --- | --- |
| IAM `app-delivery-push` | registry 단계가 session tag `delivery-project`로 assume합니다. 그 Project의 ECR repository `projects/<slug>`에만 push할 수 있습니다 |

registry 단계의 Pod 역할 `pod-role--app-delivery`(`4-role/policies/app-delivery.json`)는 `projects/*` repository를 만들고
이 역할을 assume합니다. Pod Identity association(namespace `app-delivery`, ServiceAccount `delivery-registry`)은 `5-eks`가 만듭니다.
trust policy가 그 역할을 참조하므로 `4-role` 적용 뒤에 이 디렉터리를 적용합니다.

```bash
terraform init
terraform plan
terraform apply
```
