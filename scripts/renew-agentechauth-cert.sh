#!/usr/bin/env bash

set -euo pipefail

EDGE_ROOT="${EDGE_ROOT:-/home/deploy/hetzner01/edge}"
WEBROOT="${WEBROOT:-$EDGE_ROOT/certbot/www}"
CERT_NAME="${CERT_NAME:-agentechauth.com}"
EDGE_CERT_DIR="${EDGE_CERT_DIR:-$EDGE_ROOT/certs/$CERT_NAME}"

mkdir -p "$WEBROOT"

cd "$EDGE_ROOT"
docker compose up -d nginx

renew_args=(
  certonly
  --webroot
  --webroot-path "$WEBROOT"
  --cert-name "$CERT_NAME"
  --non-interactive
  --agree-tos
  --keep-until-expiring
)

if [[ "${1:-}" == "--force-renewal" ]]; then
  renew_args+=(--force-renewal)
fi

docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -v "$WEBROOT:$WEBROOT" \
  certbot/certbot:latest "${renew_args[@]}"

docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  -v "$EDGE_CERT_DIR:$EDGE_CERT_DIR" \
  alpine:3.22 \
  sh -c "cp /etc/letsencrypt/live/$CERT_NAME/fullchain.pem '$EDGE_CERT_DIR/fullchain.pem.next' && \
    cp /etc/letsencrypt/live/$CERT_NAME/privkey.pem '$EDGE_CERT_DIR/privkey.pem.next' && \
    chmod 644 '$EDGE_CERT_DIR/fullchain.pem.next' && chmod 600 '$EDGE_CERT_DIR/privkey.pem.next' && \
    mv '$EDGE_CERT_DIR/fullchain.pem.next' '$EDGE_CERT_DIR/fullchain.pem' && \
    mv '$EDGE_CERT_DIR/privkey.pem.next' '$EDGE_CERT_DIR/privkey.pem'"

openssl x509 -in "$EDGE_CERT_DIR/fullchain.pem" -noout -subject -issuer -dates
docker compose exec -T nginx nginx -t
docker compose exec -T nginx nginx -s reload

echo "Certificate renewal and edge synchronization completed."
