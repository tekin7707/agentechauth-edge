#!/usr/bin/env bash

set -euo pipefail

EDGE_ROOT="${EDGE_ROOT:-/home/deploy/hetzner01/edge}"
EDGE_CERT_ROOT="$EDGE_ROOT/certs"

# The hook runs after every Certbot renewal. It copies every lineage that
# exists, so a newly issued product certificate joins the normal renewal path
# without granting the deploy user access to Certbot's root-owned private key.
docker run --rm \
  -v /etc/letsencrypt:/letsencrypt:ro \
  -v "$EDGE_CERT_ROOT:/edge-certs" \
  alpine:3.22 sh -eu -c '
    for cert_name in agentechauth.com cwisely.com futorya.com provengine.com; do
      source="/letsencrypt/live/$cert_name"
      destination="/edge-certs/$cert_name"
      if [ ! -r "$source/fullchain.pem" ] || [ ! -r "$source/privkey.pem" ]; then
        continue
      fi
      mkdir -p "$destination"
      cp -L "$source/fullchain.pem" "$destination/fullchain.pem.next"
      cp -L "$source/privkey.pem" "$destination/privkey.pem.next"
      chmod 644 "$destination/fullchain.pem.next"
      chmod 600 "$destination/privkey.pem.next"
      mv "$destination/fullchain.pem.next" "$destination/fullchain.pem"
      mv "$destination/privkey.pem.next" "$destination/privkey.pem"
    done
  '

cd "$EDGE_ROOT"
docker compose exec -T nginx nginx -t
docker compose exec -T nginx nginx -s reload

echo "Renewed edge certificates synchronized and Nginx reloaded."
