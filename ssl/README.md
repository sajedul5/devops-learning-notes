# HTTPS reverse proxy: Nginx + Let's Encrypt

`ssl.sh` puts any app listening on `127.0.0.1:<port>` (Node, Grafana, Jenkins, ...)
behind Nginx with a free, auto-renewing TLS certificate.

```
Browser ──HTTPS:443──▶ Nginx (TLS, security headers) ──HTTP──▶ 127.0.0.1:<APP_PORT>
         HTTP:80 ──▶ 301 redirect to HTTPS
```

## Prerequisites
- Ubuntu/Debian server with a public IP.
- DNS `A` record: `app.example.com → <server-ip>`.
- Ports 80 and 443 open (cloud security group + `ufw allow 'Nginx Full'`).

## Usage

```bash
sudo ./ssl.sh                                                     # interactive
sudo DOMAIN=app.example.com EMAIL=you@example.com APP_PORT=3000 ./ssl.sh   # non-interactive
```

Test the result at https://www.ssllabs.com/ssltest/ (aim for an A rating).
Renewal is automatic: `systemctl list-timers | grep certbot`, test with
`sudo certbot renew --dry-run`.

## What it configures
- TLS 1.2/1.3 only, HTTP→HTTPS redirect, HTTP/2.
- Security headers: HSTS, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`.
- `server_tokens off` (hides the Nginx version).
- WebSocket-friendly proxy headers and `X-Forwarded-*` for the real client IP.
- Input validation: the domain, email and port are checked before being written into
  the config, which prevents broken or injected Nginx config.

> Make sure the app itself listens on `127.0.0.1`, not `0.0.0.0`, or users can
> bypass HTTPS by hitting `http://<ip>:<port>` directly. Firewall the app port as well.
