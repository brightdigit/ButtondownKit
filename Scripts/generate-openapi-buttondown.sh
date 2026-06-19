#!/bin/bash
#
# Regenerates the committed ButtondownKit client from the vendored Buttondown
# OpenAPI spec.
#
# The swift-openapi-generator is run AHEAD OF TIME (pinned in .mise.toml via the
# spm backend) and the generated Types.swift/Client.swift are committed under
# Sources/ButtondownKit/Generated. The generator is intentionally NOT a
# Package.swift dependency and the build-tool plugin is NOT used.
#
# `swift-openapi-generator generate` honors the `filter:` key in the config, so
# a single `generate` reads the committed source spec (openapi.json) directly,
# prunes it down to the operations ButtondownKit needs (see `filter:` in
# openapi-generator-config.yaml), and emits Types.swift/Client.swift. No
# post-processing is required: the source spec is already self-consistent and
# deterministic —
#   * its `components.securitySchemes` matches the `security` refs on the kept
#     operations (so validation passes without re-injecting a scheme);
#   * the out-of-scope top-level `webhooks` object (which referenced pruned
#     schemas) has been removed; and
#   * its object keys are stored in sorted order, so the generator — which emits
#     declarations in source-document order — produces stable, reproducible
#     output run-to-run.
#
# Usage: Scripts/generate-openapi-buttondown.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

OPENAPI_DIR="${PACKAGE_DIR}/Sources/ButtondownKit/OpenAPI"
GENERATED_DIR="${PACKAGE_DIR}/Sources/ButtondownKit/Generated"
SPEC="${OPENAPI_DIR}/openapi.json"
CONFIG="${OPENAPI_DIR}/openapi-generator-config.yaml"

# Resolve the generator through mise so the pinned version is used.
if command -v mise &> /dev/null; then
  GEN="mise exec -- swift-openapi-generator"
elif command -v swift-openapi-generator &> /dev/null; then
  GEN="swift-openapi-generator"
else
  echo "Error: swift-openapi-generator not found. Install it with 'mise install'." >&2
  exit 1
fi

echo "Generating client -> ${GENERATED_DIR}"
mkdir -p "${GENERATED_DIR}"
$GEN generate \
  --config "${CONFIG}" \
  --output-directory "${GENERATED_DIR}" \
  "${SPEC}"

echo "Done. Generated files:"
ls -1 "${GENERATED_DIR}"
