# nginx-certup – Merkzettel

## Projekt
- Repo: `/home/oppe/Vorhaben/nginx-certup`
- Haupt-Skript: `certup.sh` (war früher `zert.sh`)
- Zweck: HTTPS-Einrichtung auf Debian/Ubuntu mit nginx + Certbot in einem Durchgang

## Skript-Ablauf
1. Fragt Domain, Webroot, E-Mail ab
2. HTTP-only nginx-Konfiguration → ACME-Challenge
3. `certbot certonly --webroot` → Zertifikat holen
4. nginx-Konfiguration überschreiben: HTTP→HTTPS-Redirect + SSL + PHP-FPM
5. nginx neu laden

## Bekannte Schwachstellen / offene TODOs
- PHP-Version hardcodiert: `php8.3-fpm.sock` (kein Auto-Detect)
- Kein `--static`-Flag für statische Sites (PHP-Block weglassen)
- Kein `--dry-run`-Modus
- Kein `--remove`-Befehl (Zertifikat widerrufen, Site deaktivieren)
- Keine Warnung bei falschem DNS-A-Eintrag vor certbot-Lauf

## Behobene Bugs
- Zeile 17: `=== Dies ist zert.sh` → `=== Dies ist certup.sh` (alter Name)
