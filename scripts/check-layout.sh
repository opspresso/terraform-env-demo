#!/usr/bin/env bash
# Checks the file layout rules in README.md ("Terraform 작성 규칙") for every root under demo/.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "::error file=$1::$2"; fail=1; }

# only_in <pattern> <allowed file name> <root>: the pattern may appear only in that file of the root.
only_in() {
  local pattern="$1" allowed="$2" root="$3" file
  while IFS= read -r file; do
    [[ "$(basename "$file")" == "$allowed" ]] || err "$file" "'$pattern' belongs in $allowed"
  done < <(grep -lE "$pattern" "$root"/*.tf || true)
}

# only_blocks <file> <pattern>: every top-level block of the file matches the pattern.
only_blocks() {
  local file="$1" pattern="$2" line
  [[ -f "$file" ]] || return 0
  while IFS= read -r line; do
    err "$file" "unexpected block: $line"
  done < <(grep -E '^[a-z_]+ .*\{' "$file" | grep -vE "$pattern" || true)
}

for root in demo/*/; do
  root="${root%/}"
  compgen -G "$root/*.tf" >/dev/null || continue

  version="$(sed -nE 's/^  required_version = "([^"]+)"$/\1/p' "$root/02-backend.tf" 2>/dev/null || true)"
  [[ -f "$root/02-backend.tf" ]] || err "$root" "missing 02-backend.tf"
  [[ -f "$root/00-variables.tf" ]] || err "$root" "missing 00-variables.tf"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || err "$root/02-backend.tf" "required_version must pin an exact version"
  [[ "$(cat "$root/.terraform-version" 2>/dev/null || true)" == "$version" ]] ||
    err "$root/.terraform-version" "must equal required_version ($version)"
  grep -qE '^    use_lockfile = true$' "$root/02-backend.tf" 2>/dev/null || err "$root/02-backend.tf" "backend needs use_lockfile = true"

  for file in "$root"/*.tf; do
    [[ "$(basename "$file")" =~ ^[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*\.tf$ ]] || err "$file" "name must be NN-<topic>.tf"
  done

  only_in '^variable "' 00-variables.tf "$root"
  only_in '^output "' 99-outputs.tf "$root"
  only_in '^(terraform|provider "[^"]+") \{' 02-backend.tf "$root"
  only_in '^data "terraform_remote_state" ' 02-remote-state.tf "$root"
  # The variables, backend and remote state files hold nothing else.
  only_blocks "$root/00-variables.tf" '^variable "'
  only_blocks "$root/02-backend.tf" '^(terraform|provider "[^"]+") \{'
  only_blocks "$root/02-remote-state.tf" '^data "terraform_remote_state" '
done

exit "$fail"
