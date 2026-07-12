#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0

section() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

section "Checking tracked Terraform state files"

if git ls-files | grep -Eq '(^|/).*\.tfstate(\..*)?$'; then
  git ls-files | grep -E '(^|/).*\.tfstate(\..*)?$'
  fail "Terraform state files are tracked by Git"
else
  pass "No Terraform state files are tracked"
fi

section "Checking tracked .terraform directories"

tracked_terraform_dirs="$(
  git ls-files |
    grep -E '(^|/)\.terraform/' |
    grep -v '\.terraform\.lock\.hcl$' || true
)"

if [[ -n "$tracked_terraform_dirs" ]]; then
  printf '%s\n' "$tracked_terraform_dirs"
  fail "Files from .terraform directories are tracked"
else
  pass "No provider working directories are tracked"
fi

section "Checking tracked sensitive file names"

sensitive_files="$(
  git ls-files |
    grep -Ei '(^|/)(\.env(\..*)?|credentials(\..*)?|secrets?(\..*)?|id_rsa|id_ed25519|.*\.(pem|key|p12|pfx))$' || true
)"

if [[ -n "$sensitive_files" ]]; then
  printf '%s\n' "$sensitive_files"
  fail "Potentially sensitive files are tracked"
else
  pass "No obviously sensitive file names are tracked"
fi

section "Scanning tracked files for common secret patterns"

secret_patterns='AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|AWS_SECRET_ACCESS_KEY|AWS_ACCESS_KEY_ID|AWS_SESSION_TOKEN|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|github[_-]?token|client[_-]?secret|api[_-]?key[[:space:]]*='

secret_matches="$(
  git grep -nEI "$secret_patterns" -- . \
    ':!*.md' \
    ':!scripts/security-check.sh' 2>/dev/null || true
)"

if [[ -n "$secret_matches" ]]; then
  printf '%s\n' "$secret_matches"
  fail "Potential secret values or assignments were found"
else
  pass "No common secret patterns found in tracked source files"
fi

section "Checking committed terraform.tfvars files"

tfvars_files="$(git ls-files 'infra/labs/*/terraform.tfvars' || true)"

if [[ -z "$tfvars_files" ]]; then
  pass "No committed terraform.tfvars files found"
else
  tfvars_matches="$(
    grep -nEi \
      '(password|secret|token|access[_-]?key|private[_-]?key|client[_-]?secret)[[:space:]]*=' \
      $tfvars_files 2>/dev/null || true
  )"

  if [[ -n "$tfvars_matches" ]]; then
    printf '%s\n' "$tfvars_matches"
    fail "Potential sensitive assignments found in terraform.tfvars"
  else
    pass "Committed terraform.tfvars contain no obvious sensitive assignments"
  fi
fi

section "Checking generated deployment artifacts"

generated_files="$(
  git ls-files |
    grep -E '(^|/)\.generated/|task-definition-.*\.json$|appspec-.*\.json$|revision.*\.zip$' || true
)"

if [[ -n "$generated_files" ]]; then
  printf '%s\n' "$generated_files"
  fail "Generated deployment artifacts are tracked"
else
  pass "Generated deployment artifacts are not tracked"
fi

section "Security check summary"

if (( failures > 0 )); then
  printf '\nSecurity check failed with %d issue(s).\n' "$failures" >&2
  exit 1
fi

printf '\nAll repository security checks passed.\n'
