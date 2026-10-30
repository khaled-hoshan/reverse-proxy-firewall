# Architecture

## Overview

This project configures Nginx as a reverse proxy in front of a locally running Python web application. It adds HTTPS encryption, HTTP-to-HTTPS redirection, and a default-deny firewall policy.

Let's Encrypt provides the TLS certificate. DNS-01 validation is performed through the DuckDNS API using custom Certbot authentication and cleanup hooks.

## Request Flow

1. A client sends an HTTP or HTTPS request to the server.
2. UFW permits incoming traffic on the required ports: 22, 80, and 443.
3. Nginx receives the request.
4. HTTP requests are redirected to HTTPS.
5. HTTPS requests are handled using the Let's Encrypt certificate.
6. Nginx forwards the request to the Python application at `127.0.0.1:8080`.
7. The application processes the request and returns a response through Nginx.

## Components

### Python Web Application

- Runs as a dedicated systemd service.
- Listens on `127.0.0.1:8080`.
- Provides a `/health` endpoint.
- Is not directly exposed to external network interfaces.

### Nginx

- Listens on ports 80 and 443.
- Redirects HTTP traffic to HTTPS.
- Proxies requests to the local Python application.
- Forwards relevant client and protocol headers.
- Hides the Nginx version from HTTP response headers.

### UFW Firewall

- Default incoming policy: deny.
- Default outgoing policy: allow.
- Allows SSH (22), HTTP (80), and HTTPS (443).
- Does not allow external access to the application port (8080).

### Let's Encrypt and Certbot

- Issues a trusted TLS certificate for the DuckDNS hostname.
- Uses DNS-01 validation through DuckDNS.
- Uses custom authentication and cleanup hooks to manage the DNS TXT challenge record.
- Uses Certbot's systemd timer for scheduled renewal attempts.
- Reloads Nginx through a deploy hook after successful certificate renewal.

## Network Security

The Python application binds only to the loopback interface. This means external clients cannot connect directly to port 8080.

External HTTP and HTTPS requests are intended to enter through Nginx, which acts as the controlled entry point to the application.

## Deployment Environment and Limitation

The project was tested inside an Ubuntu virtual machine hosted through QEMU/KVM with libvirt NAT networking.

Local HTTPS requests, certificate validation, HTTP redirection, firewall configuration, and Certbot renewal simulation were verified successfully.

External inbound connectivity could not be established in the tested mobile-hotspot and virtual-machine NAT environment. Therefore, successful local HTTPS validation should not be interpreted as proof that the service is publicly reachable.
