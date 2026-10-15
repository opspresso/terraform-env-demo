#!/usr/bin/env bash
# Run in a disposable root container with this module mounted at /src.
set -euo pipefail

test_bin="$(mktemp -d)"
export PATH="$test_bin:$PATH"
export K3S_TEST_EVENTS=/tmp/k3s-resource-events
export K3S_TEST_FAIL_ONCE=/tmp/k3s-resource-fail-once
destination=/etc/systemd/system/k3s.service.d/30-agent-studio-resources.conf
image_gc_destination=/var/lib/rancher/k3s/agent/etc/kubelet.conf.d/30-agent-studio-image-gc.conf
mkdir -p "$(dirname "$image_gc_destination")"
echo 'unrelated configuration' > "$(dirname "$image_gc_destination")/90-unrelated.conf"

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

# Image policy drift alone must trigger one restart, then converge to a no-op.
sed -i 's/imageGCHighThresholdPercent: 70/imageGCHighThresholdPercent: 85/' "$image_gc_destination"
bash /src/configure-k3s-resources.sh 1536
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 2 ]]
bash /src/configure-k3s-resources.sh 1536
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 2 ]]

# A failed restart restores the preceding value, restarts it, and remains failed.
echo 'previous image policy' > "$image_gc_destination"
touch "$K3S_TEST_FAIL_ONCE"
if bash /src/configure-k3s-resources.sh 2048; then
  echo 'expected the failed profile change to return failure' >&2
  exit 1
fi
grep -qx 'Environment=GOMEMLIMIT=1536MiB' "$destination"
grep -qx 'previous image policy' "$image_gc_destination"
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 4 ]]

# Invalid input must not mutate the profile or restart the service.
if bash /src/configure-k3s-resources.sh invalid; then
  exit 1
fi
grep -qx 'Environment=GOMEMLIMIT=1536MiB' "$destination"
grep -qx 'previous image policy' "$image_gc_destination"
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 4 ]]

# Adding image GC to an existing memory-only profile must also roll back cleanly.
rm "$image_gc_destination"
touch "$K3S_TEST_FAIL_ONCE"
if bash /src/configure-k3s-resources.sh 1536; then
  exit 1
fi
grep -qx 'Environment=GOMEMLIMIT=1536MiB' "$destination"
[[ ! -e "$image_gc_destination" ]]
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 6 ]]

# A failed first application restores absence of the owned drop-in.
rm "$destination"
touch "$K3S_TEST_FAIL_ONCE"
if bash /src/configure-k3s-resources.sh 1536; then
  exit 1
fi
[[ ! -e "$destination" ]]
[[ ! -e "$image_gc_destination" ]]
grep -qx 'unrelated configuration' "$(dirname "$image_gc_destination")/90-unrelated.conf"
[[ $(grep -c '^systemctl restart k3s$' "$K3S_TEST_EVENTS") == 8 ]]
echo 'PASS: first apply, no-op apply, image policy drift, rollback of both files, and invalid input'
