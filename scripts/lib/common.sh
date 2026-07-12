#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

AWS_REGION="${AWS_REGION:-us-east-1}"

log() {
  printf "\n==> %s\n" "$1"
}

fail() {
  printf "ERROR: %s\n" "$1" >&2
  exit 1
}

require_command() {
  local command_name="$1"

  command -v "$command_name" >/dev/null 2>&1 || {
    fail "Required command '$command_name' is not installed or not in PATH."
  }
}