# Setup Guide

This guide describes how to configure Nginx as a reverse proxy, secure the server with UFW, and enable HTTPS using Let's Encrypt and Certbot on Ubuntu 24.04.

## 1. Prerequisites

- Ubuntu 24.04
- A Python web application running as a systemd service and listening on `127.0.0.1:8080`
- A DuckDNS subdomain
- A DuckDNS API token
- Nginx, UFW, Certbot, and curl

The examples use:

```text
elevvo-lab.duckdns.org
```

Replace this hostname and the DuckDNS domain identifier where necessary if using a different domain.

## 2. Install Required Packages

```bash
sudo apt update
sudo apt install nginx ufw certbot curl dnsutils -y
```

Enable Nginx:

```bash
sudo systemctl enable --now nginx
```

## 3. Configure UFW Firewall

Set the default firewall policies:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow SSH, HTTP, and HTTPS:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

Enable the firewall:

```bash
sudo ufw enable
```

Verify:

```bash
sudo ufw status verbose
```

Port `8080` must not have an incoming firewall rule because the Python application should only be accessible through the local machine.

## 4. Configure DuckDNS DNS-01 Hooks

Create a protected directory for the DuckDNS API token:

```bash
sudo install -d -m 700 /root/.secrets
sudo nano /root/.secrets/duckdns-token
```

Place the API token in the file and save it.

Restrict its permissions:

```bash
sudo chmod 600 /root/.secrets/duckdns-token
```

Install the authentication and cleanup scripts:

```bash
sudo install -m 700 scripts/duckdns-auth.sh /usr/local/bin/duckdns-auth.sh
sudo install -m 700 scripts/duckdns-cleanup.sh /usr/local/bin/duckdns-cleanup.sh
```

The scripts read the API token from `/root/.secrets/duckdns-token`.

They use the DuckDNS domain identifier `elevvo-lab`. If using another subdomain, update the `domains` value in both scripts.

## 5. Obtain the TLS Certificate

Request a certificate using Certbot and DNS-01 validation:

```bash
sudo certbot certonly \
  --manual \
  --preferred-challenges dns \
  --manual-auth-hook /usr/local/bin/duckdns-auth.sh \
  --manual-cleanup-hook /usr/local/bin/duckdns-cleanup.sh \
  --non-interactive \
  --agree-tos \
  --email YOUR_EMAIL \
  -d elevvo-lab.duckdns.org
```

Replace `YOUR_EMAIL` with your email address.

The authentication hook updates the DuckDNS TXT record required for domain validation. The cleanup hook removes the temporary TXT record afterward.

Verify the certificate:

```bash
sudo certbot certificates
```

The expected certificate paths are:

```text
/etc/letsencrypt/live/elevvo-lab.duckdns.org/fullchain.pem
/etc/letsencrypt/live/elevvo-lab.duckdns.org/privkey.pem
```

## 6. Configure Nginx Reverse Proxy

Copy the repository configuration into Nginx:

```bash
sudo cp nginx/user-web.conf /etc/nginx/sites-available/user-web
```

The configuration contains:

- An HTTP server block that redirects requests to HTTPS.
- An HTTPS server block that uses the Let's Encrypt certificate.
- A reverse proxy forwarding requests to `127.0.0.1:8080`.
- Forwarded headers containing the original host, client IP, and protocol.

The certificate must exist before enabling this configuration.

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/user-web /etc/nginx/sites-enabled/user-web
sudo rm -f /etc/nginx/sites-enabled/default
```

Disable Nginx version disclosure by adding the following directive inside the `http {}` block in `/etc/nginx/nginx.conf`:

```nginx
server_tokens off;
```

Test the configuration:

```bash
sudo nginx -t
```

If the test succeeds, reload Nginx:

```bash
sudo systemctl reload nginx
```

## 7. Configure Automatic Certificate Renewal

Enable the Certbot systemd timer:

```bash
sudo systemctl enable --now certbot.timer
```

Install the Nginx deployment hook:

```bash
sudo install -d -m 755 /etc/letsencrypt/renewal-hooks/deploy

sudo install -m 700 scripts/reload-nginx.sh \
  /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

The deployment hook reloads Nginx after a successful certificate renewal so that Nginx uses the renewed certificate.

Test the renewal process:

```bash
sudo certbot renew --dry-run
```

Check the timer:

```bash
systemctl status certbot.timer
```

## 8. Final Verification

### Check Nginx

```bash
sudo nginx -t
sudo systemctl is-active nginx
```

### Check UFW

```bash
sudo ufw status verbose
```

Confirm that the default incoming policy is `deny` and that ports 22, 80, and 443 are allowed.

### Check Backend Isolation

```bash
sudo ss -lntp | grep 8080
```

The application should listen on `127.0.0.1:8080`, not `0.0.0.0:8080`.

### Test HTTPS

```bash
curl -i https://elevvo-lab.duckdns.org/health
```

Expected result: HTTP 200 with the application health response.

### Test HTTP-to-HTTPS Redirection

```bash
curl -I http://elevvo-lab.duckdns.org/health
```

Expected result: HTTP 301 with a `Location` header pointing to the HTTPS URL.

### Verify Nginx Version Hiding

```bash
curl -I https://elevvo-lab.duckdns.org/health
```

The response should contain a `Server` header without exposing the Nginx version.

## 9. Local Testing Without Public Inbound Access

If the server is behind NAT or public inbound connectivity is unavailable, test the HTTPS configuration locally:

```bash
curl -i --resolve elevvo-lab.duckdns.org:443:127.0.0.1 \
  https://elevvo-lab.duckdns.org/health
```

Test the HTTP redirect locally:

```bash
curl -I --resolve elevvo-lab.duckdns.org:80:127.0.0.1 \
  http://elevvo-lab.duckdns.org/health
```

These tests validate local Nginx behavior and TLS certificate verification. They do not prove that the service is reachable from the public internet.
