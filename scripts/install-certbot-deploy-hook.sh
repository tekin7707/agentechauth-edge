#!/usr/bin/env bash

set -euo pipefail

EDGE_ROOT="${EDGE_ROOT:-/home/deploy/hetzner01/edge}"
HOOK_DIR="/etc/letsencrypt/renewal-hooks/deploy"
HOOK_NAME="50-sync-edge-certificates"

docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v "$EDGE_ROOT:$EDGE_ROOT:ro" \
  alpine:3.22 \
  sh -c "install -d '$HOOK_DIR' && install -m 755 '$EDGE_ROOT/scripts/check-and-sync-edge-certificates.sh' '$HOOK_DIR/$HOOK_NAME'"

echo "Installed Certbot deploy hook: $HOOK_DIR/$HOOK_NAME"
