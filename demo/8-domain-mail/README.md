# 도메인 메일

`admin@opspresso.com`으로 받은 메일을 지정한 외부 메일함으로 전달하고, 같은 주소로 SES SMTP 발신을 제공합니다.
Route 53과 서울 리전의 기존 SES 계정을 사용합니다. 상시 서버·전용 IP·Mail Manager endpoint는 만들지 않습니다.

## 메일 사용

- 수신: `admin@opspresso.com` → SES Receipt Rule → S3 → Lambda → 지정한 메일함.
- 발신: 메일 앱 → SES SMTP → 수신자. 발신 주소는 `admin@opspresso.com`만 허용합니다.
- SMTP: `email-smtp.ap-northeast-2.amazonaws.com`, 포트 `587`, `STARTTLS`.
- 사용자명과 비밀번호는 별도로 생성한 SMTP 자격 증명을 사용합니다. Gmail 비밀번호를 사용하지 않습니다.
- 수신 메일의 본문·첨부 파일은 유지합니다. 인증 가능한 자체 도메인으로 `From`을 바꾸고, 원래 발신자 또는 명시된 회신 주소를 `Reply-To`에 넣습니다.
- 외부 메일함에서 일반 답장을 보내면 그 메일함의 주소가 발신자가 됩니다. `admin`으로 답장하려면 SES SMTP를 지정한 발신 identity를 선택합니다.

Thunderbird에서는 기존 Gmail 계정에 `admin@opspresso.com` identity를 추가하고 이 SMTP 서버를 연결할 수 있습니다.
[Thunderbird identity 안내](https://support.mozilla.org/en-US/kb/using-identities).
Gmail의 외부 주소 `Send as` 기능은 2027년 1월 종료 예정이며, 새 설정이 제한될 수 있습니다.
외부에서 Gmail로 전달받는 기능은 계속 지원합니다.
[Google 안내](https://support.google.com/mail/answer/17101213).

## 배포

Terraform `>= 1.15.8, < 2.0`, Python 3, AWS CLI가 필요합니다. AWS 계정은 provider에서 제한합니다.
서울 리전 SES의 production access와 발신 허용 상태를 먼저 확인합니다.
수신 rule set은 리전마다 하나만 활성화할 수 있으므로 다른 활성 rule set이 있으면 적용 전에 함께 설계해야 합니다.

1. 권한 있는 AWS profile을 `AWS_PROFILE`로 지정합니다.
2. Git에서 제외되는 `private.auto.tfvars`를 권한 `0600`으로 만들고 `forward_to`에 실제 전달 주소를 지정합니다.
   이 값은 Terraform의 민감한 값으로 취급하지만 S3 state와 Lambda 환경 설정에는 저장됩니다. 계정 접근 권한으로 보호해야 합니다.
3. `terraform init`, `terraform fmt -check`, `terraform validate`, `python3 -m unittest discover -s tests -v`를 실행합니다.
4. `receive_enabled = false`인 상태에서 plan을 검토하고 적용합니다. 기존 MX·SPF는 import하며 값은 유지합니다.
5. SES identity의 DKIM·MAIL FROM 인증 성공, Lambda와 수신 규칙, SMTP 권한을 확인합니다.
6. `receive_enabled = true`로 변경하고 plan을 검토한 뒤 적용합니다. 도메인의 기존 Lark MX·SPF가 SES로 바뀝니다.
   이 도메인에서 수신할 주소는 `admin`뿐입니다. 다른 주소는 수신 규칙과 별도 전달 대상을 추가해야 합니다.
7. 외부 메일에서 수신·회신을 확인하고 Lambda 로그·S3 처리 태그를 확인합니다.

실제 전달 주소와 SMTP 자격 증명을 Git·PR·로그에 넣지 않습니다. Terraform plan 파일도 민감한 값이 있으므로 보관·공유에 주의합니다.

SMTP 자격 증명은 Terraform state에 넣지 않고 다음 명령으로 생성합니다.

```bash
python3 create-smtp-credentials.py --profile "$AWS_PROFILE"
```

결과는 `~/.config/opspresso-mail/smtp.json`에 권한 `0600`으로 저장합니다. 기존 파일이나 IAM key가 있으면 중단합니다.
재발급할 때는 기존 키 사용처를 확인한 뒤 IAM에서 폐기하고 새 키를 설정합니다.
SMTP IAM 사용자를 삭제할 때도 이 스크립트가 만든 키를 먼저 폐기해야 합니다. Terraform이 관리하지 않는 키를 강제로 삭제하지 않습니다.

## 비용과 보관

SES 계정 요금제는 다른 도메인과 공유하므로 이 모듈이 변경하지 않습니다.
현재 요금은 [SES 요금표](https://aws.amazon.com/ses/pricing/)에서 확인합니다.
전달 한 건마다 SES 수신 1건과 발신 1건이 발생하고, 직접 보낸 메일은 발신으로 추가 과금됩니다.
S3·Lambda·SQS·CloudWatch는 사용량에 따라 과금됩니다. 기존 Route 53 hosted zone을 재사용합니다.

- 전달 완료 원본: 7일 후 S3 만료 대상.
- 미전달·격리 원본: 30일 후 S3 만료 대상.
- Lambda 로그: 7일. 메일 제목·본문·주소는 기록하지 않습니다.
- Lambda가 재시도 후에도 실패하면 SQS failure queue에 이벤트를 최대 14일 보관합니다.

SES의 스팸 또는 바이러스 판정이 `FAIL`이면 전달하지 않고 원본에 `delivery=quarantined` 태그를 붙입니다.
스캔 결과가 없거나 `GRAY`·`PROCESSING_FAILED`이면 SES 자체 차단 외에 이 함수는 차단하지 않으며, 최종 메일함의 필터도 적용됩니다.
전달 루프는 `delivery=loop`, 성공은 `delivery=forwarded`로 기록합니다.
처리 완료 태그가 있는 이벤트의 재실행은 건너뜁니다. SES 발신 성공 직후 태그 기록 전 장애가 나거나 이벤트가 동시에 실행되면 중복 전달될 수 있습니다.

## 실패 확인과 복구

`terraform output function_name`, `terraform output mail_bucket`, `terraform output failure_queue_url`로 리소스 이름을 확인합니다.

```bash
aws logs tail /aws/lambda/opspresso-admin-mail --since 1h --region ap-northeast-2
aws sqs get-queue-attributes --queue-url "$(terraform output -raw failure_queue_url)" \
  --attribute-names ApproximateNumberOfMessagesVisible --region ap-northeast-2
```

로그의 message ID로 S3 `incoming/<message-id>` 원본과 태그를 확인합니다. 격리 메일은 첨부 파일을 실행하지 않고 검토합니다.
실패 원인을 해결한 후 SQS의 원래 SES 이벤트를 Lambda에 다시 전달합니다. 성공한 재처리가 확인되면 해당 SQS 메시지를 삭제합니다.
큐와 격리 원본은 주기적으로 확인해야 하며, 이 구성은 별도 알림 구독을 만들지 않습니다.

수신 전환을 되돌릴 때는 이전 서비스가 실제 수신 가능한지 먼저 확인합니다. `receive_enabled=false`를 적용하면 Lark MX·SPF로 되돌아갑니다.
S3 bucket은 `prevent_destroy`로 보호하며, DNS를 되돌려도 보관 원본을 삭제하지 않습니다.
