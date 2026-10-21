# 도메인 메일

`admin@opspresso.com` 수신은 Cloudflare Email Routing, 발신은 서울 리전 Amazon SES를 사용합니다.
Cloudflare가 원본 `From`을 유지하여 지정한 외부 메일함으로 전달합니다. 전달 규칙과 목적지 주소는 Cloudflare 대시보드에서 관리합니다.

## 메일 사용

- 수신: `admin@opspresso.com` → Cloudflare Email Routing → 지정한 개인 메일함.
- 발신: 메일 앱 → SES SMTP → 수신자. 발신 주소는 `admin@opspresso.com`만 허용합니다.
- SMTP: `email-smtp.ap-northeast-2.amazonaws.com`, 포트 `587`, `STARTTLS`.
- SMTP 사용자명과 비밀번호는 `~/.config/opspresso-mail/smtp.json`에 권한 `0600`으로 보관합니다. Gmail 비밀번호를 사용하지 않습니다.
- 개인 메일함에서 일반 답장을 보내면 개인 주소가 발신자로 사용됩니다. `admin`으로 답장하려면 SES SMTP를 연결한 발신 identity를 선택합니다.

Thunderbird는 기존 Gmail 계정에 별도 발신 identity와 SMTP 서버를 연결할 수 있습니다.
[Thunderbird 안내](https://support.mozilla.org/en-US/kb/using-identities).
Gmail의 외부 주소 `Send as` 기능은 2027년 1월 종료 예정이며 새 설정이 제한될 수 있습니다.
외부에서 Gmail로 전달받는 기능은 계속 지원합니다.
[Google 안내](https://support.google.com/mail/answer/17101213).

## 관리 경계

- 도메인 등록·네임서버 위임: 개인 AWS 계정의 Route 53 Domains.
- 공개 DNS·수신 전달: Cloudflare의 `opspresso.com` zone, Free 요금제.
- SES identity·MAIL FROM·SMTP IAM 사용자: 이 Terraform 구성, Opspresso AWS 계정.
- 기존 Route 53 zone: 캐시된 이전 위임에서도 수신이 이어지도록 Cloudflare MX·SPF를 반영한 사본.
- 이전 SES 수신 원본·로그: 기존 S3 보관 정책과 로그 보관 기간을 유지합니다.

Cloudflare가 권한 DNS입니다. 기존 Route 53 zone의 레코드만 수정하면 공개 DNS에 반영되지 않습니다.
이 모듈의 `terraform output -json ses_dns_records`에 표시되는 DKIM·MAIL FROM·DMARC 레코드는 Cloudflare에도 동일하게 유지해야 합니다.
`demo/3-alb` 등 이전 Route 53 기반 환경을 다시 배포할 때도 공개 DNS 관리 대상을 먼저 맞춰야 합니다.

## 전환과 검증

Terraform `>= 1.15.8, < 2.0`, Python 3, AWS CLI가 필요합니다. 이 모듈은 Opspresso AWS 계정으로 실행합니다.

1. Route 53의 전체 레코드를 백업하고 Cloudflare Free zone에 가져옵니다. A·AAAA alias는 같은 대상의 CNAME으로 옮깁니다.
   기존 웹서비스 동작을 유지하려면 레코드를 DNS only로 설정합니다. SES DKIM과 `mail.opspresso.com` MX·SPF도 보존합니다.
2. Cloudflare에서 전달 목적지를 인증하고 `admin@opspresso.com`의 전달 규칙을 구성합니다.
3. 모든 기존 레코드를 확인한 뒤 등록기관의 네임서버를 Cloudflare가 지정한 값으로 변경합니다. DNSSEC를 사용 중이면 DS 처리도 함께 확인합니다.
4. Cloudflare Email Routing의 MX·SPF를 확인하고, 동일한 MX 값을 미추적 `private.auto.tfvars`의 `cloudflare_mx_records`에 지정합니다.
   실제 개인 메일 주소나 자격 증명을 Git·PR·로그에 넣지 않습니다.
5. 권한 있는 profile을 `AWS_PROFILE`로 지정하고 `terraform init`, `terraform fmt -check`, `terraform validate`를 실행합니다.
   전환 작업에서는 먼저 `terraform plan -target=aws_route53_record.mx -target=aws_route53_record.spf -out=terraform.tfplan`으로 이전 zone의 MX·SPF 변경만 검토하고 적용합니다.
   기존 MX TTL인 60초 이상 기다린 뒤 이전 Route 53 nameserver도 Cloudflare MX를 응답하는지 확인합니다. 이 단계의 targeting은 수신 중단을 막기 위한 일회성 전환 절차입니다.
6. 전체 `terraform plan`으로 SES 발신 identity·SMTP 사용자·S3 원본을 보존하고 이전 전달 함수·수신 규칙만 정리하는지 확인합니다.
   실패 큐가 비어 있고 활성 SES rule set이 이 모듈의 것인지 확인한 뒤 적용합니다. 다른 rule set이 활성화되어 있으면 삭제를 중단하고 소유 관계부터 확인합니다.
7. 외부 계정에서 수신 주소로 테스트 메일을 보내 목적지 도착과 원본 `From` 보존을 확인합니다.
   SES SMTP 발신과 DKIM·SPF·DMARC 통과, 기존 웹사이트 응답도 확인합니다.

네임서버 캐시가 남은 동안 이전 Route 53 zone을 삭제하지 않습니다. 되돌릴 때는 실제 수신 가능한 경로를 먼저 복구하고 네임서버를 변경합니다.

## SMTP 자격 증명

```bash
python3 create-smtp-credentials.py --profile "$AWS_PROFILE"
```

위 명령은 `admin` 발신만 허용하는 IAM 사용자의 키를 발급해 로컬 파일에 저장합니다. 비밀번호는 Terraform state에 저장하지 않습니다.
기존 파일이나 IAM key가 있으면 중단합니다. 재발급·사용자 삭제 전에는 기존 키 사용처를 확인하고 명시적으로 폐기해야 합니다.

## 비용과 원본 보관

Cloudflare의 기본 수신 전달은 무료입니다. 임의 수신자에게 보내는 메일은 SES에서 사용량에 따라 과금됩니다.
Cloudflare 유료 발신·Workers Paid·전용 IP·Mail Manager endpoint는 사용하지 않습니다.
공유 SES 계정의 요금제는 다른 도메인에도 영향을 주므로 이 모듈에서 변경하지 않습니다.
[Cloudflare 요금](https://developers.cloudflare.com/email-service/platform/pricing/), [SES 요금](https://aws.amazon.com/ses/pricing/).

이전 S3 원본은 전달 완료 후 7일, 미전달·격리 원본은 생성 후 30일에 만료 대상이 됩니다. 이전 Lambda 로그는 7일 보관합니다.
S3 bucket은 `prevent_destroy`로 보호합니다. Cloudflare로 전환한 뒤 새 수신 메일은 이 bucket에 저장되지 않습니다.
