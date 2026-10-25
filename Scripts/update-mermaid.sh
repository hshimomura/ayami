#!/bin/zsh
# Reproduce the audited runtime; updating versions requires reviewing the hashes too.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
AUDIT_DIR="$(mktemp -d /private/tmp/ayami-mermaid.XXXXXX)"
trap '[[ "$AUDIT_DIR" == /private/tmp/ayami-mermaid.* ]] && rm -r -- "$AUDIT_DIR"' EXIT
curl --fail --location --silent --show-error \
  https://registry.npmjs.org/mermaid/-/mermaid-12.2.0.tgz \
  --output "$AUDIT_DIR/mermaid.tgz"
EXPECTED_ARCHIVE=071914164d0f6d53e5c26a10a220230d4ae8d37ed0f2263fbf072266f0af3a0a
ACTUAL_ARCHIVE="$(shasum -a 256 "$AUDIT_DIR/mermaid.tgz" | cut -d ' ' -f 1)"
[[ "$ACTUAL_ARCHIVE" == "$EXPECTED_ARCHIVE" ]] || { print -u2 'Mermaid archive checksum mismatch'; exit 1; }
tar -xzf "$AUDIT_DIR/mermaid.tgz" -C "$AUDIT_DIR" package/dist/mermaid.min.js package/LICENSE
EXPECTED_RUNTIME=a8a6a6f805b074a8261a2825c86f99c8054acb3b35f50bb7e24a4f9f2c3c3b9f
ACTUAL_RUNTIME="$(shasum -a 256 "$AUDIT_DIR/package/dist/mermaid.min.js" | cut -d ' ' -f 1)"
[[ "$ACTUAL_RUNTIME" == "$EXPECTED_RUNTIME" ]] || { print -u2 'Mermaid runtime checksum mismatch'; exit 1; }
ditto "$AUDIT_DIR/package/dist/mermaid.min.js" "$PROJECT_ROOT/Sources/Ayami/Resources/Mermaid/mermaid.min.js"
ditto "$AUDIT_DIR/package/LICENSE" "$PROJECT_ROOT/Legal/Mermaid-LICENSE.txt"
print 'Installed verified Mermaid 12.2.0 (offline browser bundle).'
