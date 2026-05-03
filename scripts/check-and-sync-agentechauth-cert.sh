#!/usr/bin/env bash

set -euo pipefail

LETSENCRYPT_DIR="${LETSENCRYPT_DIR:-/etc/letsencrypt/live/agentechauth.com}"
EDGE_CERT_DIR="${EDGE_CERT_DIR:-/home/deploy/hetzner01/edge/certs/agentechauth.com}"

mkdir -p "$EDGE_CERT_DIR"

if [[ ! -r "$LETSENCRYPT_DIR/fullchain.pem" || ! -r "$LETSENCRYPT_DIR/privkey.pem" ]]; then
  echo "Cannot read Let's Encrypt files in $LETSENCRYPT_DIR" >&2
  exit 1
fi

echo "Certificate SAN entries:"
openssl x509 -in "$LETSENCRYPT_DIR/fullchain.pem" -noout -text | grep "DNS:"

cp "$LETSENCRYPT_DIR/fullchain.pem" "$EDGE_CERT_DIR/fullchain.pem"
cp "$LETSENCRYPT_DIR/privkey.pem" "$EDGE_CERT_DIR/privkey.pem"

chmod 644 "$EDGE_CERT_DIR/fullchain.pem"
chmod 600 "$EDGE_CERT_DIR/privkey.pem"

cat <<EOF
Certificate copied to:
  $EDGE_CERT_DIR/fullchain.pem
  $EDGE_CERT_DIR/privkey.pem

If 'fiload.agentechauth.com' is missing from the SAN list above, renew the cert with certbot before reloading edge.
EOF
