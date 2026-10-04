#!/usr/bin/env bash
# Run in a disposable root container with this module mounted at /src.
set -euo pipefail

test_bin="$(mktemp -d)"
export PATH="$test_bin:$PATH"
export K3S_TEST_EVENTS=/tmp/k3s-resource-events
export K3S_TEST_FAIL_ONCE=/tmp/k3s-resource-fail-once
destination=/etc/systemd/system/k3s.service.d/30-agent-studio-resources.conf

cat > "$test_bin/systemctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "systemctl $*" >> "$K3S_TEST_EVENTS"
if [[ "$1" == restart && -f "$K3S_TEST_FAIL_ONCE" ]]; then
  rm "$K3S_TEST_FAIL_ONCE"
  exit 1
fi
SH
cat > "$test_bin/k3s" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "k3s $*" >> "$K3S_TEST_EVENTS"
SH
chmod +x "$test_bin/systemctl" "$test_bin/k3s"

# A new setting restarts once, and an identical setting only checks readiness.
bash /src/configure-k3s-resources.sh 1536
grep -qx 'Environment=GOMEMLIMIT=1536MiB' "$destination"
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 1 ]]
bash /src/configure-k3s-resources.sh 1536
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 1 ]]

# A failed restart restores the preceding value, restarts it, and remains failed.
touch "$K3S_TEST_FAIL_ONCE"
if bash /src/configure-k3s-resources.sh 2048; then
  echo 'expected the failed profile change to return failure' >&2
  exit 1
fi
grep -qx 'Environment=GOMEMLIMIT=1536MiB' "$destination"
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 3 ]]

# Invalid input must not mutate the profile or restart the service.
if bash /src/configure-k3s-resources.sh invalid; then
  exit 1
fi
grep -qx 'Environment=GOMEMLIMIT=1536MiB' "$destination"
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 3 ]]

# A failed first application restores absence of the owned drop-in.
rm "$destination"
touch "$K3S_TEST_FAIL_ONCE"
if bash /src/configure-k3s-resources.sh 1536; then
  exit 1
fi
[[ ! -e "$destination" ]]
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 5 ]]
echo 'PASS: first apply, no-op apply, rollback with/without a preceding file, and invalid input'
