#!/usr/bin/env bash
set -euo pipefail

memory_mib="${1:?pass the k3s Go memory budget in MiB}"
if [[ ! "$memory_mib" =~ ^[0-9]+$ ]] || ((memory_mib < 1024 || memory_mib > 3072)); then
  echo "memory budget must be an integer from 1024 through 3072 MiB" >&2
  exit 2
fi
if ((EUID != 0)); then
  echo "run as root" >&2
  exit 1
fi

systemctl is-active --quiet k3s
destination=/etc/systemd/system/k3s.service.d/30-agent-studio-resources.conf
candidate="$(mktemp)"
previous="$(mktemp)"
trap 'rm -f "$candidate" "$previous"' EXIT
printf '[Service]\nEnvironment=GOMEMLIMIT=%sMiB\n' "$memory_mib" > "$candidate"

if cmp -s "$candidate" "$destination"; then
  k3s kubectl get --raw=/readyz
  echo "k3s resource profile unchanged"
  exit 0
fi

had_previous=false
if [[ -f "$destination" ]]; then
  cp -p "$destination" "$previous"
  had_previous=true
fi
install -d -m 0755 /etc/systemd/system/k3s.service.d
install -m 0644 "$candidate" "$destination"
systemctl daemon-reload

restart_and_check() {
  systemctl restart k3s &&
    k3s kubectl wait --for=condition=Ready node --all --timeout=120s &&
    k3s kubectl get --raw=/readyz
}

if ! restart_and_check; then
  echo "k3s readiness failed; restoring the previous owned resource profile" >&2
  if "$had_previous"; then
    cp -p "$previous" "$destination"
  else
    rm -f "$destination"
  fi
  systemctl daemon-reload
  restart_and_check
  exit 1
fi
echo "k3s resource profile applied: GOMEMLIMIT=${memory_mib}MiB"
