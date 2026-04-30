#!/usr/bin/env bash
set -euo pipefail

# Downloads Lambda artifacts from terraform-aws-github-runner releases.
# The release tag MUST match github-aws-runners/github-runner/aws version in ../main.tf
# (e.g. release v6.10.1 corresponds to Terraform module version 6.10.1).

RELEASE_TAG="${1:?usage: $0 <release tag e.g. v6.10.1>}"
MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${MODULE_ROOT}/.lambda-dist"
BASE_URL="https://github.com/github-aws-runners/terraform-aws-github-runner/releases/download/${RELEASE_TAG}"
ASSETS=(
  webhook.zip
  runners.zip
  runner-binaries-syncer.zip
)

mkdir -p "${OUT_DIR}"

for zip in "${ASSETS[@]}"; do
  tmp="${OUT_DIR}/${zip}.part"
  curl -fsSL "${BASE_URL}/${zip}" -o "${tmp}"
  mv -f "${tmp}" "${OUT_DIR}/${zip}"
done
