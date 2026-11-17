# Nginx Reverse Proxy & Perimeter Firewall

The project configures Nginx as a reverse proxy for a Python web application, secures incoming traffic using UFW, and enables HTTPS using Let's Encrypt and Certbot with DNS-01 validation through DuckDNS.

## Project Objectives

- Configure Nginx as a reverse proxy.
- Redirect HTTP requests to HTTPS.
- Obtain and configure a trusted TLS certificate.
- Automate certificate renewal using Certbot hooks.
- Configure a default-deny firewall policy using UFW.
- Prevent direct external access to the backend application.
- Hide the Nginx version from HTTP response headers.
- Verify the configuration through practical tests.

## Architecture

```text
                  Client
                    |
                    |
              HTTP / HTTPS
                    |
                    v
             +-------------+
             |     UFW     |
             | Firewall    |
             +-------------+
                    |
                    v
             +-------------+
             |    Nginx    |
             | Reverse     |
             | Proxy       |
             +-------------+
                    |
                    | HTTPS terminates here
                    |
                    v
          http://127.0.0.1:8080
                    |
                    v
             +-------------+
             |   Python    |
             | Web Service |
             +-------------+
                    |
                    v
              /health
```

Nginx acts as the public-facing entry point. The Python application listens only on the loopback interface at `127.0.0.1:8080`, preventing direct external access to the backend.

For more details, see [Architecture](docs/architecture.md).

## Technologies Used

| Technology | Purpose |
|---|---|
| Ubuntu 24.04 | Server operating system |
| Nginx | Reverse proxy and TLS termination |
| UFW | Host-based firewall |
| Let's Encrypt | Free TLS certificates |
| Certbot | Certificate issuance and renewal |
| DuckDNS | Dynamic DNS and DNS-01 challenge |
| Bash | Authentication, cleanup, and deployment hooks |
| systemd | Service and timer management |
| Python | Backend web application |
| Git | Version control |

## Implementation

### 1. Nginx Reverse Proxy

- Configured Nginx to listen on ports 80 and 443.
- Redirected HTTP requests to HTTPS using HTTP 301.
- Forwarded HTTPS requests to the Python backend.
- Configured forwarding headers for client and protocol information.
- Disabled Nginx version disclosure using `server_tokens off`.

### 2. Firewall Configuration

Configured UFW with:

- Default incoming policy: `deny`.
- Default outgoing policy: `allow`.
- Allowed TCP ports: `22`, `80`, and `443`.
- No incoming rule for backend port `8080`.

### 3. TLS Certificate and Renewal

Obtained a Let's Encrypt certificate using DNS-01 validation through DuckDNS.

Implemented three scripts:

- `duckdns-auth.sh`: Creates the DNS TXT challenge record.
- `duckdns-cleanup.sh`: Removes the temporary TXT record.
- `reload-nginx.sh`: Reloads Nginx after successful certificate renewal.

The DuckDNS API token is stored separately in a root-protected file and is not included in this repository.

### 4. Backend Isolation

The Python application listens on:

```text
127.0.0.1:8080
```

This ensures that the backend is accessible locally by Nginx rather than directly through an externally exposed network interface.

## Verification Results

The following tests were successfully performed:

| Test | Expected result | Result |
|---|---|---|
| Nginx configuration test | Successful syntax validation | Passed |
| UFW status | Default deny incoming | Passed |
| HTTPS health endpoint | HTTP 200 | Passed |
| HTTP redirection | HTTP 301 to HTTPS | Passed |
| TLS certificate validation | Trusted certificate and matching hostname | Passed |
| Nginx version hiding | No version in Server header | Passed |
| Backend isolation | Listening on `127.0.0.1:8080` | Passed |
| Certbot renewal simulation | Successful dry-run | Passed |
| Nginx deploy hook | Successful manual execution | Passed |
| External inbound connectivity | Public connection established | Not verified |

### Network Limitation

The project was deployed inside an Ubuntu virtual machine using QEMU/KVM and libvirt NAT networking.

Local HTTPS requests, certificate validation, HTTP redirection, firewall configuration, and Certbot renewal simulation were verified successfully.

External inbound connectivity could not be established in the tested mobile-hotspot and virtual-machine NAT environment. Public accessibility is therefore not claimed as a verified result.

## Repository Structure

```text
elevvo-task-2/
├── README.md
├── .gitignore
├── nginx/
│   └── user-web.conf
├── scripts/
│   ├── duckdns-auth.sh
│   ├── duckdns-cleanup.sh
│   └── reload-nginx.sh
├── docs/
│   ├── architecture.md
│   ├── setup-guide.md
│   └── troubleshooting.md
└── evidence/
```

## Setup Guide

For installation and configuration instructions, see:

[Setup Guide](docs/setup-guide.md)

For common issues and diagnostic commands, see:

[Troubleshooting](docs/troubleshooting.md)

## Security Considerations

- The backend listens only on localhost.
- UFW blocks unsolicited incoming traffic by default.
- HTTPS protects client-to-proxy communication.
- The DuckDNS API token is stored outside the repository.
- TLS private keys and certificates are not committed.
- Nginx version disclosure is disabled.

