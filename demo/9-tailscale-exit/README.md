# Oregon Tailscale exit node

`Client → Tailscale → tailscale-exit (Oregon) → Internet`

클라이언트에서 `tailscale-exit` 를 exit node 로 선택하면 웹사이트에는
오레곤 EC2 의 공인 IP 가 표시됩니다.
[Tailscale exit node 문서](https://tailscale.com/docs/features/exit-nodes)

## 구성

- 리전: `us-west-2`, AZ: `us-west-2a`
- EC2: `t4g.nano` (ARM64, 2 vCPU, 512 MiB), Amazon Linux 2023
- 디스크: 암호화된 `gp3` 8 GiB, swap 1 GiB
- 네트워크: 오레곤 기본 VPC 및 `us-west-2a` 기본 public subnet, 공인 IPv4
- 인바운드: SSH 용 TCP `22`, Tailscale 직접 연결용 UDP `41641` (`0.0.0.0/0`)
- 관리: SSH 또는 AWS Systems Manager Session Manager
- SSH key pair: `nalbam-bruce` (오레곤 리전에 등록된 key pair)
- Bootstrap: Tailscale 설치, IP forwarding, 재부팅 시 UDP offload 및 서비스 복원
- State: 기존 서울 S3 backend 의 별도 `tailscale-exit` key 사용

기본 VPC/subnet 은 data source 로 조회합니다. 오레곤 기본 VPC 와 해당
AZ 의 기본 subnet 이 존재하며 인터넷으로 향하는 IGW 경로가 있어야 합니다.
현재 기본 VPC 는 IPv4 전용이므로 이 exit node 는 IPv6 인터넷 통신을 지원하지
않습니다. IPv6 전용 사이트에는 접속할 수 없습니다.

VPC, NAT Gateway, ALB, Elastic IP 는 만들지 않습니다. EC2 외에 공인 IPv4,
EBS, 인터넷 데이터 전송 요금이 발생합니다. CPU credit 은 `standard` 로
설정하여 추가 credit 요금 없이 운영하며, credit 이 소진되면 CPU 성능이
baseline 으로 제한됩니다. 장시간 고속 전송이 필요하면 인스턴스 크기를 조정합니다.
[T4g 사양](https://aws.amazon.com/ec2/instance-types/t4/),
[EC2 요금](https://aws.amazon.com/ec2/pricing/on-demand/)

## 생성

저장소와 같은 Terraform `1.15.8`, AWS provider `6.60.0` 을 사용합니다.

```bash
cd demo/9-tailscale-exit
terraform init
terraform plan
terraform apply
terraform output
```

EC2 부팅이 끝나면 `nalbam-bruce` 의 개인 키로 공인 IP 에 SSH 접속합니다.

```bash
ssh -i /path/to/private-key ec2-user@"$(terraform output -raw public_ip)"
```

SSM 등록이 끝나면 AWS 콘솔의 Session Manager 로 연결하거나,
AWS CLI 및 Session Manager plugin 이 있는 환경에서 실행합니다.

```bash
aws ssm start-session --region us-west-2 --target "$(terraform output -raw instance_id)"
```

SSM 접속 권한은 이 명령을 실행하는 AWS 사용자/role 에도 필요합니다.

## Tailscale 등록

SSH 또는 Session Manager 의 EC2 셸에서 bootstrap 완료를 기다린 뒤 로그인합니다.
표시된 URL 을 열어 클라이언트와 같은 tailnet 에 등록합니다.

```bash
sudo cloud-init status --wait
sudo systemctl is-active amazon-ssm-agent tailscale-udp-offload tailscaled
sudo tailscale up --hostname=tailscale-exit --advertise-exit-node --accept-dns=false
sudo tailscale ip -4
```

인증 키는 Terraform 변수, state, EC2 user data 에 저장하지 않습니다.
`--accept-dns=false` 는 EC2 자체의 AWS DNS 설정을 유지하여 Amazon Linux 의
DNS forwarding loop 를 피합니다. 클라이언트의 DNS 설정을 끄는 옵션이 아닙니다.
[Amazon Linux DNS 설명](https://tailscale.com/docs/reference/linux-dns)

[Tailscale Machines](https://login.tailscale.com/admin/machines) 에서
`tailscale-exit` 의 **Edit exit node → Allow exit node routing → Save** 를 승인합니다.
상시 운영할 노드는 같은 관리 화면에서 **Disable key expiry** 를 설정합니다.
사용자 지정 ACL/grants 를 쓰는 tailnet 은 클라이언트에서
`autogroup:internet` 으로 접속하는 권한도 허용되어 있어야 합니다.
Exit node 승인과 인터넷 사용 권한은 별개입니다.

Tailscale 등록 후 `nalbam-bruce` 의 개인 키로 SSH 접속할 수도 있습니다.
Tailnet 의 ACL/grants 에서 클라이언트의 노드 TCP `22` 접근이 허용되어야 합니다.

```bash
ssh -i /path/to/private-key ec2-user@tailscale-exit
```

MagicDNS 를 사용하지 않으면 호스트 이름 대신 EC2 에서 확인한
`sudo tailscale ip -4` 결과를 사용합니다.

## 클라이언트에서 사용

macOS Tailscale 메뉴에서 **Exit Nodes → tailscale-exit** 를 선택합니다.
집/회사 LAN 도 사용하려면 **Allow Local Network Access** 를 켭니다.
CLI 가 제공되는 설치에서는 다음 명령도 사용할 수 있습니다.

```bash
tailscale set --exit-node=tailscale-exit --exit-node-allow-lan-access=true
tailscale status
tailscale ping tailscale-exit
curl -4 https://checkip.amazonaws.com
```

IPv4 결과가 `terraform output -raw public_ip` 와 같으면 인터넷 트래픽이
EC2 를 경유한 것입니다.
미국 판정은 사용하는 사이트의 IP 위치 데이터에 따라 확인합니다.

해제하려면 메뉴에서 **Exit Nodes → None** 을 선택하거나 실행합니다.

```bash
tailscale set --exit-node= --exit-node-allow-lan-access=false
```

## 운영

```bash
# EC2 의 Session Manager 셸에서 실행
sudo journalctl -u tailscaled -u tailscale-udp-offload --no-pager -n 100
sudo tail -n 100 /var/log/cloud-init-output.log
sudo sysctl net.ipv4.ip_forward net.ipv6.conf.all.forwarding
sudo swapon --show
```

공인 IPv4 는 stop/start 또는 인스턴스 교체 시 바뀔 수 있지만, 클라이언트는
Tailscale 이름으로 선택합니다. Bootstrap 변경은 인스턴스를 교체하므로 새 노드를
Tailscale 에 등록하고 exit node 로 승인한 뒤 이전 노드를 관리 화면에서 제거합니다.
AMI 최신 버전만으로는 기존 노드를 자동 교체하지 않습니다.
