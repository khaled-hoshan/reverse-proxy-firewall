# Troubleshooting

Common issues encountered when configuring Nginx, UFW, and Let's Encrypt.

## 1. Nginx Fails to Start

**Possible causes:**
- Invalid Nginx configuration syntax.
- Missing TLS certificate files.
- Another process is already using ports 80 or 443.

**Diagnosis:**

```bash
sudo nginx -t
sudo systemctl status nginx
sudo journalctl -u nginx -n 50 --no-pager
sudo ss -lntp
```

**Resolution:**

Correct the reported configuration error, ensure certificate files exist, and verify that ports 80 and 443 are available.

## 2. HTTP Works but HTTPS Fails

**Possible causes:**
- Missing or incorrectly referenced certificate files.
- Incorrect certificate hostname.
- Nginx is not listening on port 443.

**Diagnosis:**

```bash
sudo certbot certificates
sudo nginx -t
sudo ss -lntp | grep ':443'
```

**Resolution:**

Verify the certificate paths and hostname in the Nginx configuration, then reload Nginx.

## 3. HTTP Does Not Redirect to HTTPS

**Diagnosis:**

```bash
curl -I http://elevvo-lab.duckdns.org/health
```

**Expected result:**

```text
HTTP/1.1 301 Moved Permanently
Location: https://elevvo-lab.duckdns.org/health
```

**Resolution:**

Verify that the HTTP server block contains the correct redirect directive and that the intended Nginx site is enabled.

## 4. Nginx Returns 502 Bad Gateway

**Possible causes:**
- The Python application is stopped.
- The backend is listening on the wrong address or port.
- Nginx cannot connect to the backend.

**Diagnosis:**

```bash
sudo systemctl status user-web
sudo ss -lntp | grep 8080
curl -i http://127.0.0.1:8080/health
```

**Resolution:**

Start or repair the application service and verify that it listens on `127.0.0.1:8080`.

## 5. Certbot DNS-01 Validation Fails

**Possible causes:**
- Incorrect DuckDNS API token.
- Incorrect domain identifier.
- TXT record has not propagated.
- Authentication hook failed.

**Diagnosis:**

```bash
sudo bash -n /usr/local/bin/duckdns-auth.sh
sudo bash -n /usr/local/bin/duckdns-cleanup.sh

dig TXT _acme-challenge.elevvo-lab.duckdns.org
```

Inspect Certbot logs:

```bash
sudo tail -n 50 /var/log/letsencrypt/letsencrypt.log
```

**Resolution:**

Verify the protected token file, domain identifier, and DNS TXT record. Do not expose the API token in terminal output, screenshots, or Git commits.

## 6. Certbot Renewal Fails

**Diagnosis:**

```bash
sudo certbot renew --dry-run
systemctl status certbot.timer
```

**Resolution:**

Verify that the authentication and cleanup hooks are executable and that the DNS challenge can be completed successfully.

## 7. External Connections Fail

A service can work locally while remaining unreachable from the public internet.

**Diagnosis:**

```bash
sudo ufw status verbose
sudo ss -lntp
```

Also check the host's NAT configuration, port forwarding, and network provider restrictions.

**Important:**

In this project, local HTTPS and certificate validation succeeded, but external inbound connectivity could not be established in the tested mobile-hotspot and libvirt NAT environment. This does not establish that the Nginx configuration itself is failing.
