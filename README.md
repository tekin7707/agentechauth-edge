# Edge proxy

## Certificate renewal

Port 80 stays on Nginx. ACME HTTP-01 challenges are served from
`certbot/www/.well-known/acme-challenge`, so Certbot must use the `webroot`
authenticator instead of `standalone`.

One-time server setup:

```sh
./scripts/install-certbot-deploy-hook.sh
```

Deploys call `prepare-edge-certificates.sh`, which synchronizes Certbot files in a
short-lived root container. Private keys remain `root:root 600`; the unprivileged
deploy user never needs to read or weaken them.

Urgent/manual renewal (safe while Nginx is running):

```sh
./scripts/renew-agentechauth-cert.sh --force-renewal
```

The host Certbot timer runs the deploy hook, which atomically copies every managed
certificate (`agentechauth.com`, `cwisely.com`, `futorya.com`, and
`provengine.com`) into `certs/<domain>`, validates Nginx configuration, and
reloads Nginx. Verify the complete renewal path after infrastructure changes with:

```sh
docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -v /home/deploy/hetzner01/edge/certbot/www:/home/deploy/hetzner01/edge/certbot/www \
  certbot/certbot:latest renew --cert-name agentechauth.com --dry-run --no-random-sleep-on-renew
```
