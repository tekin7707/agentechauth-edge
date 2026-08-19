#!/usr/bin/env bash

set -euo pipefail

EDGE_ROOT="${EDGE_ROOT:-/home/deploy/hetzner01/edge}"
EDGE_CERT_ROOT="$EDGE_ROOT/certs"

mkdir -p \
  "$EDGE_CERT_ROOT/agentechauth.com" \
  "$EDGE_CERT_ROOT/cwisely.com" \
  "$EDGE_CERT_ROOT/futorya.com" \
  "$EDGE_CERT_ROOT/provengine.com"

# Private keys produced by Certbot are intentionally root-owned and mode 600.
# The deploy user must not read or loosen them. A short-lived root container
# validates/copies the files while Nginx keeps consuming the same read-only bind.
docker run --rm \
  -v /etc/letsencrypt:/letsencrypt:ro \
  -v "$EDGE_CERT_ROOT:/edge-certs" \
  alpine:3.22 sh -eu -c '
    prepare_cert() {
      cert_name="$1"
      required="$2"
      destination="/edge-certs/$cert_name"
      letsencrypt_source="/letsencrypt/live/$cert_name"

      mkdir -p "$destination"
      if [ -r "$letsencrypt_source/fullchain.pem" ] && [ -r "$letsencrypt_source/privkey.pem" ]; then
        echo "Synchronizing $cert_name from Certbot"
        cp "$letsencrypt_source/fullchain.pem" "$destination/fullchain.pem.next"
        cp "$letsencrypt_source/privkey.pem" "$destination/privkey.pem.next"
        chmod 644 "$destination/fullchain.pem.next"
        chmod 600 "$destination/privkey.pem.next"
        mv "$destination/fullchain.pem.next" "$destination/fullchain.pem"
        mv "$destination/privkey.pem.next" "$destination/privkey.pem"
      elif [ -r "$destination/fullchain.pem" ] && [ -r "$destination/privkey.pem" ]; then
        echo "Using existing root-protected certificate for $cert_name"
      elif [ "$required" = "true" ]; then
        echo "Certificate source not found for $cert_name" >&2
        exit 1
      else
        echo "No certificate exists yet for optional $cert_name"
        return
      fi

      test -s "$destination/fullchain.pem"
      test -s "$destination/privkey.pem"
      chmod 644 "$destination/fullchain.pem"
      chmod 600 "$destination/privkey.pem"
    }

    prepare_cert agentechauth.com true
    prepare_cert cwisely.com true
    prepare_cert futorya.com true
    prepare_cert provengine.com false
  '

echo "Edge certificates are present with root-only private-key permissions."
