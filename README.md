# Edge proxy

## AgentechAuth certificate renewal

Port 80 stays on Nginx. ACME HTTP-01 challenges are served from
`certbot/www/.well-known/acme-challenge`, so Certbot must use the `webroot`
authenticator instead of `standalone`.

One-time server setup:

```sh
./scripts/install-certbot-deploy-hook.sh
```

Urgent/manual renewal (safe while Nginx is running):

```sh
./scripts/renew-agentechauth-cert.sh --force-renewal
```

The host Certbot timer renews `/etc/letsencrypt/live/agentechauth.com`. The deploy
hook atomically copies the renewed certificate into `certs/agentechauth.com`,
validates Nginx configuration, and reloads Nginx. Verify the complete renewal path
after infrastructure changes with:

```sh
docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -v /home/deploy/hetzner01/edge/certbot/www:/home/deploy/hetzner01/edge/certbot/www \
  certbot/certbot:latest renew --cert-name agentechauth.com --dry-run --no-random-sleep-on-renew
```
