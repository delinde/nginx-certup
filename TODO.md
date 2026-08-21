# TODO / Roadmap

Ideas and open tasks for `zert.sh`. Contributions welcome.

---

## Testing still needed

- [ ] Fresh install on a clean Debian 12 VM (no prior nginx/certbot config)
- [ ] Fresh install on Ubuntu 24.04
- [ ] Domain with `www.` subdomain in addition to bare domain
      (certbot `-d example.com -d www.example.com`)
- [ ] Webroot that is a symlink rather than a real directory
- [ ] Running the script when nginx is not yet installed (error message?)
- [ ] Running the script when certbot is not installed (error message?)
- [ ] Behaviour when DNS is not yet propagated (certbot will fail – message clear enough?)

---

## User messages / output

- [ ] Check that all error messages are clear enough for first-time users
- [x] Add a short summary before anything is written so the user can confirm
- [x] Colour the final success line green
- [x] Print the exact URLs to open for testing

---

## Features / improvements

- [x] Ask for email address interactively if `CERTBOT_EMAIL` is not set
- [ ] PHP version: currently hardcoded to `php8.3-fpm.sock`;
      auto-detect installed version or ask the user
- [ ] Option flag `--static` to skip the PHP-FPM block (for static sites)
- [ ] Support for multiple domains on one certificate (SAN / `-d d1 -d d2`)
- [ ] `--dry-run` mode: show what would be done without touching any files
- [ ] `--remove` / uninstall option: disable site, revoke certificate, clean up
- [ ] Warn if the domain's A record does not point to this server's IP
      (avoids a certbot failure that is hard to interpret)
- [ ] `CERTBOT_EMAIL` could alternatively be stored in `/etc/zert.conf`
