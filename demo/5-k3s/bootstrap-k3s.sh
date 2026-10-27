#!/usr/bin/env bash

set -euo pipefail

if ((EUID != 0)); then
  echo "run as root: sudo $0" >&2
  exit 1
fi

# This script is mirrored from ../dockpad/scripts/bootstrap-k3s.sh.

# shellcheck disable=SC1091
source /etc/os-release

architecture="$(uname -m)"
case "$architecture" in
  x86_64|amd64) ;;
  *) echo "unsupported architecture: $architecture (requires x86_64/amd64)" >&2; exit 1 ;;
esac

case "${ID:-}" in
  # Amazon Linux ships curl-minimal, which already provides curl and conflicts
  # with the full curl package from the Amazon Linux repository.
  amzn) dnf install -y tar git iptables socat conntrack-tools ;;
  ubuntu|debian)
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl tar git iptables socat conntrack
    ;;
  *) echo "unsupported Linux distribution: ${ID:-unknown}" >&2; exit 1 ;;
esac

echo "== install Node.js"
if ! command -v node >/dev/null 2>&1; then
  case "${ID:-}" in
    amzn) dnf install -y nodejs ;;
    ubuntu|debian) DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs ;;
  esac
else
  echo "node is already installed"
fi

echo "== install GitHub CLI"
if ! command -v gh >/dev/null 2>&1; then
  case "${ID:-}" in
    amzn)
      curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo -o /etc/yum.repos.d/gh-cli.repo
      dnf install -y gh
      ;;
    ubuntu|debian)
      type -p wget >/dev/null || apt-get install -y wget
      mkdir -p -m 755 /etc/apt/keyrings
      wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        > /etc/apt/keyrings/githubcli-archive-keyring.gpg
      chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      printf '%s\n' \
        'deb [arch='"$(dpkg --print-architecture)"' signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' \
        > /etc/apt/sources.list.d/github-cli.list
      apt-get update
      apt-get install -y gh
      ;;
  esac
else
  echo "gh is already installed"
fi

echo "== install helm"
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "helm is already installed"
fi

echo "== install Argo CD CLI"
if ! command -v argocd >/dev/null 2>&1; then
  argocd_binary="$(mktemp)"
  curl -fsSL https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 \
    -o "$argocd_binary"
  install -m 0755 "$argocd_binary" /usr/local/bin/argocd
  rm -f "$argocd_binary"
else
  echo "argocd is already installed"
fi

echo "== install k9s"
if ! command -v k9s >/dev/null 2>&1; then
  temp_dir="$(mktemp -d)"
  trap 'rm -rf -- "$temp_dir"' EXIT
  curl -fsSL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz \
    | tar -xzf - -C "$temp_dir" k9s
  install -m 0755 "$temp_dir/k9s" /usr/local/bin/k9s
else
  echo "k9s is already installed"
fi

echo "== install k3s"
if ! command -v k3s >/dev/null 2>&1; then
  export INSTALL_K3S_CHANNEL="${K3S_CHANNEL:-stable}"
  if [[ -n "${K3S_VERSION:-}" ]]; then
    export INSTALL_K3S_VERSION="$K3S_VERSION"
  fi
  curl -sfL https://get.k3s.io | sh -s - server
else
  echo "k3s is already installed"
fi
systemctl enable --now k3s

admin_user="${SUDO_USER:-ec2-user}"
id "$admin_user" >/dev/null 2>&1 || { echo "user does not exist: $admin_user" >&2; exit 1; }
admin_home="$(getent passwd "$admin_user" | cut -d: -f6)"
install -d -m 0700 -o "$admin_user" -g "$admin_user" "$admin_home/.kube"
install -m 0600 -o "$admin_user" -g "$admin_user" /etc/rancher/k3s/k3s.yaml "$admin_home/.kube/config"

echo "== configure ECR image pull credentials"
install -m 0750 -d /usr/local/sbin
cat > /usr/local/sbin/refresh-k3s-ecr-secret <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

region="${AWS_REGION:-ap-northeast-2}"
account_id="${AWS_ACCOUNT_ID:-396608815058}"
registry="${account_id}.dkr.ecr.${region}.amazonaws.com"
kubectl=(k3s kubectl)

password="$(aws ecr get-login-password --region "$region")"
for namespace in agent-memory agent-studio; do
  "${kubectl[@]}" create namespace "$namespace" --dry-run=client -o yaml \
    | "${kubectl[@]}" apply -f - >/dev/null
  "${kubectl[@]}" create secret docker-registry ecr-registry \
    --namespace "$namespace" \
    --save-config \
    --docker-server="$registry" \
    --docker-username=AWS \
    --docker-password="$password" \
    --dry-run=client -o yaml \
    | "${kubectl[@]}" apply -f - >/dev/null
done
EOF
chmod 0750 /usr/local/sbin/refresh-k3s-ecr-secret

cat > /etc/systemd/system/k3s-ecr-secret.service <<'EOF'
[Unit]
Description=Refresh ECR pull credentials for k3s applications
After=k3s.service
Requires=k3s.service

[Service]
Type=oneshot
Environment=AWS_REGION=ap-northeast-2
Environment=AWS_ACCOUNT_ID=396608815058
ExecStart=/usr/local/sbin/refresh-k3s-ecr-secret
EOF

cat > /etc/systemd/system/k3s-ecr-secret.timer <<'EOF'
[Unit]
Description=Refresh ECR pull credentials for k3s applications

[Timer]
OnBootSec=1min
OnUnitActiveSec=6h
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now k3s-ecr-secret.timer
systemctl start k3s-ecr-secret.service

echo "== verify installed tools"
git --version
node --version
gh --version | head -n 1
helm version --short
argocd version --client
k9s version --short
KUBECONFIG="$admin_home/.kube/config" k3s kubectl wait --for=condition=Ready node --all --timeout=120s
KUBECONFIG="$admin_home/.kube/config" k3s kubectl get nodes -o wide
