#!/usr/bin/env bash

set -euo pipefail

LETSENCRYPT_DIR="${LETSENCRYPT_DIR:-/etc/letsencrypt/live/agentechauth.com}"
EDGE_CERT_DIR="${EDGE_CERT_DIR:-/home/deploy/hetzner01/edge/certs/agentechauth.com}"
EDGE_ROOT="${EDGE_ROOT:-/home/deploy/hetzner01/edge}"

mkdir -p "$EDGE_CERT_DIR"

if [[ ! -r "$LETSENCRYPT_DIR/fullchain.pem" || ! -r "$LETSENCRYPT_DIR/privkey.pem" ]]; then
  echo "Cannot read Let's Encrypt files in $LETSENCRYPT_DIR" >&2
  exit 1
fi

echo "Certificate SAN entries:"
openssl x509 -in "$LETSENCRYPT_DIR/fullchain.pem" -noout -text | grep "DNS:"

install -m 644 "$LETSENCRYPT_DIR/fullchain.pem" "$EDGE_CERT_DIR/fullchain.pem.next"
install -m 600 "$LETSENCRYPT_DIR/privkey.pem" "$EDGE_CERT_DIR/privkey.pem.next"
mv "$EDGE_CERT_DIR/fullchain.pem.next" "$EDGE_CERT_DIR/fullchain.pem"
mv "$EDGE_CERT_DIR/privkey.pem.next" "$EDGE_CERT_DIR/privkey.pem"

chmod 644 "$EDGE_CERT_DIR/fullchain.pem"
chmod 600 "$EDGE_CERT_DIR/privkey.pem"

cd "$EDGE_ROOT"
docker compose exec -T nginx nginx -t
docker compose exec -T nginx nginx -s reload

echo "Certificate copied and edge Nginx reloaded."
