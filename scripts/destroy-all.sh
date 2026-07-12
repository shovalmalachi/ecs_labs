#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LABS_DIR="$ROOT_DIR/infra/labs"

echo
echo "========================================="
echo " Destroying all Terraform labs"
echo "========================================="

for LAB in "$LABS_DIR"/*; do

    [[ -d "$LAB" ]] || continue

    LAB_NAME="$(basename "$LAB")"

    if [[ ! -f "$LAB/main.tf" ]]; then
        continue
    fi

    echo
    echo ">>> Destroying: $LAB_NAME"

    terraform -chdir="$LAB" destroy -auto-approve || {
        echo "Failed to destroy $LAB_NAME"
    }

done

echo
echo "========================================="
echo " All destroy operations completed"
echo "========================================="
