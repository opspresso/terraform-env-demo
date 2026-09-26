#!/usr/bin/env bash

set -euo pipefail

if ((EUID != 0)); then
  echo "run as root: sudo $0" >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "amzn" || "${VERSION_ID:-}" != "2023" ]]; then
  echo "unsupported Linux distribution: requires Amazon Linux 2023" >&2
  exit 1
fi

case "$(uname -m)" in
  aarch64|arm64) ;;
  *) echo "unsupported architecture: requires aarch64/arm64" >&2; exit 1 ;;
esac

# DNF and the SSM agent need headroom on the 512 MiB instance.
echo "== configure swap"
if [[ ! -f /swapfile ]]; then
  (umask 077; dd if=/dev/zero of=/swapfile bs=1M count=1024 status=none)
  mkswap /swapfile
fi
chmod 0600 /swapfile
if ! swapon --show=NAME --noheadings | grep -Fxq /swapfile; then
  swapon /swapfile
fi
if ! grep -Eq '^/swapfile[[:space:]]' /etc/fstab; then
  printf '%s\n' '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "== install Tailscale"
curl -fsSL https://pkgs.tailscale.com/stable/amazon-linux/2023/tailscale.repo \
  -o /etc/yum.repos.d/tailscale.repo
dnf install -y tailscale iptables ethtool amazon-ssm-agent

echo "== enable IP forwarding"
cat > /etc/sysctl.d/99-tailscale.conf <<'EOF'
net.ipv4.ip_forward = 1
# Tailscale advertises both families; this VPC provides IPv4 internet egress.
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p /etc/sysctl.d/99-tailscale.conf

# Configure UDP offload on every boot, after the network is online.
install -d -m 0755 /usr/local/sbin
cat > /usr/local/sbin/configure-tailscale-offload <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

netdev="$(ip -o route get 1.1.1.1 | awk '{for (i=1; i<=NF; i++) if ($i=="dev") {print $(i+1); exit}}')"
ethtool -K "$netdev" rx-udp-gro-forwarding on rx-gro-list off
EOF
chmod 0755 /usr/local/sbin/configure-tailscale-offload

cat > /etc/systemd/system/tailscale-udp-offload.service <<'EOF'
[Unit]
Description=Configure UDP forwarding offload for the Tailscale exit node
Wants=network-online.target
After=network-online.target
Before=tailscaled.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/configure-tailscale-offload
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "== start services"
systemctl daemon-reload
systemctl enable --now tailscale-udp-offload tailscaled

# IAM credentials can reach IMDS after the preinstalled SSM agent starts.
# Restart it after credentials are available to clear its registration backoff.
echo "== wait for EC2 instance role credentials"
python3 - <<'PY'
import json
import time
import urllib.error
import urllib.parse
import urllib.request

base_url = "http://169.254.169.254"
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
request = urllib.request.Request(
    base_url + "/latest/api/token",
    method="PUT",
    headers={"X-aws-ec2-metadata-token-ttl-seconds": "300"},
)
with opener.open(request, timeout=3) as response:
    token = response.read().decode()

def read_metadata(path):
    request = urllib.request.Request(
        base_url + path,
        headers={"X-aws-ec2-metadata-token": token},
    )
    with opener.open(request, timeout=3) as response:
        return response.read().decode()

deadline = time.monotonic() + 180
while True:
    try:
        role = read_metadata("/latest/meta-data/iam/security-credentials/").strip()
        credentials = json.loads(read_metadata(
            "/latest/meta-data/iam/security-credentials/" + urllib.parse.quote(role, safe="")
        ))
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
    else:
        if credentials.get("Code") != "Success" or not all(
            credentials.get(field) for field in ("AccessKeyId", "SecretAccessKey", "Token")
        ):
            raise RuntimeError("EC2 instance role credentials are invalid")
        print("EC2 instance role credentials are available")
        break

    if time.monotonic() >= deadline:
        raise TimeoutError("Timed out waiting for EC2 instance role credentials")
    time.sleep(2)
PY
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

# Set preferences without logging a one-time login URL in cloud-init output.
# Keep the instance's AWS DNS resolver to avoid Amazon Linux DNS loops.
tailscale set --hostname=tailscale-exit --advertise-exit-node --accept-dns=false

echo "== verify services"
systemctl is-active amazon-ssm-agent tailscale-udp-offload tailscaled
tailscale version
echo "Authenticate once through Session Manager:"
echo "sudo tailscale up --hostname=tailscale-exit --advertise-exit-node --accept-dns=false"
