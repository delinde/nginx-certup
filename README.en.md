# nginx-letsencrypt-setup

A single Bash script (`zert.sh`) that sets up a fully working HTTPS site on
Debian/Ubuntu in one go:

- writes an nginx virtual-host configuration
- obtains a Let's Encrypt certificate via Certbot
- rewrites the configuration for HTTPS with an HTTP → HTTPS redirect
- reloads nginx

Tested on Debian 12 / Ubuntu 24.04 with nginx and PHP 8.3-FPM.

---

## Prerequisites

| Package | Purpose |
|---|---|
| `nginx` | Web server |
| `certbot` | Let's Encrypt client |
| `python3-certbot-nginx` | (optional) Certbot nginx plugin |
| `php8.3-fpm` | PHP processor (adjust version as needed) |

Your domain must already point to the server's IP address (DNS A record).

The webroot directory must exist **before** running the script.
By default the script expects: `/home/www/<domain>/html`

---

## Installation

```bash
sudo curl -o /usr/local/bin/zert.sh \
  https://raw.githubusercontent.com/Delinde/nginx-letsencrypt-setup/main/zert.sh
sudo chmod +x /usr/local/bin/zert.sh
```

---

## Usage

```bash
zert.sh [domain]
```

The script asks two questions:

```
Domain (e.g. example.com): example.com
Webroot [/home/www/example.com/html]:
```

- **Domain** – can be pre-filled by passing it as an argument.
- **Webroot** – press Enter to accept the suggested path, or type a different
  one (useful when two domains should share the same content directory).

### Example: two domains, one content folder

```
zert.sh example.com
  Domain: example.com        ↵
  Webroot: /home/www/example.com/html   ↵

zert.sh alias.example.com
  Domain: alias.example.com  ↵
  Webroot: /home/www/example.com/html   ← type this, then ↵
```

### Email address for Let's Encrypt

Set the environment variable `CERTBOT_EMAIL` before running the script to
register your address with Let's Encrypt (recommended for renewal reminders):

```bash
export CERTBOT_EMAIL=you@example.com
zert.sh example.com
```

Without it the certificate is obtained without an email address.

---

## What the script does, step by step

1. Asks for domain and webroot.
2. Verifies the webroot directory exists.
3. Writes a minimal HTTP-only nginx config (needed for the ACME challenge).
4. Enables the site and reloads nginx.
5. Runs `certbot certonly --webroot` to obtain the certificate.
6. Overwrites the nginx config with the full HTTPS version
   (HTTP → HTTPS redirect + SSL block with PHP-FPM support).
7. Reloads nginx again.

The script is safe to run a second time on the same domain: the symlink in
`sites-enabled` is only created once, and Certbot skips renewal when the
certificate is still valid.

---

## File locations created

| File | Description |
|---|---|
| `/etc/nginx/sites-available/<domain>` | nginx virtual-host config |
| `/etc/nginx/sites-enabled/<domain>` | symlink to the above |
| `/etc/letsencrypt/live/<domain>/` | certificate files |

---

## Contributing

Bug reports, pull requests, and suggestions are welcome — see [TODO.md](TODO.md).
