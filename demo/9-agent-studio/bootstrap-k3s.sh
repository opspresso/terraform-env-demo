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

echo "== verify installed tools"
git --version
gh --version | head -n 1
helm version --short
argocd version --client
k9s version --short
KUBECONFIG="$admin_home/.kube/config" k3s kubectl wait --for=condition=Ready node --all --timeout=120s
KUBECONFIG="$admin_home/.kube/config" k3s kubectl get nodes -o wide
