# nginx-certup

Ein einziges Bash-Skript (`certup.sh`), das auf Debian/Ubuntu in einem Durchgang
eine vollständig funktionierende HTTPS-Website einrichtet:

- schreibt eine nginx-Virtual-Host-Konfiguration
- holt ein Let's-Encrypt-Zertifikat via Certbot
- schreibt die Konfiguration für HTTPS mit HTTP → HTTPS-Weiterleitung um
- lädt nginx neu

Getestet auf Debian 12 / Ubuntu 24.04 mit nginx und PHP 8.3-FPM.

---

## Voraussetzungen

| Paket | Zweck |
|---|---|
| `nginx` | Webserver |
| `certbot` | Let's-Encrypt-Client |
| `python3-certbot-nginx` | (optional) Certbot-nginx-Plugin |
| `php8.3-fpm` | PHP-Prozessor (Version ggf. anpassen) |

Die Domain muss bereits auf die IP-Adresse des Servers zeigen (DNS-A-Eintrag).

Das Webroot-Verzeichnis muss **vor** dem Skriptaufruf vorhanden sein.
Standardmäßig erwartet das Skript: `/home/www/<domain>/html`

---

## Installation

```bash
sudo curl -o /usr/local/bin/certup.sh \
  https://raw.githubusercontent.com/delinde/nginx-certup/main/certup.sh
sudo chmod +x /usr/local/bin/certup.sh
```

---

## Verwendung

```bash
certup.sh [domain]
```

Das Skript stellt drei Fragen:

```
Domain (z.B. example.com): example.com
Webroot [/home/www/example.com/html]:
E-Mail-Adresse:
```

- **Domain** – kann als Argument übergeben werden.
- **Webroot** – Enter drücken, um den vorgeschlagenen Pfad zu übernehmen, oder
  einen anderen eingeben (nützlich, wenn zwei Domains denselben Inhaltsordner
  teilen sollen).
- **E-Mail** – empfohlen für Ablauf-Erinnerungen von Let's Encrypt; kann
  leer gelassen werden.

### Beispiel: zwei Domains, ein Inhaltsordner

```
certup.sh example.com
  Domain: example.com        ↵
  Webroot: /home/www/example.com/html   ↵

certup.sh alias.example.com
  Domain: alias.example.com  ↵
  Webroot: /home/www/example.com/html   ← hier eintragen, dann ↵
```

### E-Mail-Adresse alternativ als Umgebungsvariable

```bash
export CERTBOT_EMAIL=ich@example.com
certup.sh example.com
```

---

## Was das Skript tut – Schritt für Schritt

1. Fragt Domain, Webroot und E-Mail-Adresse ab.
2. Zeigt eine Zusammenfassung und fragt nach Bestätigung.
3. Prüft, ob das Webroot-Verzeichnis existiert.
4. Schreibt eine minimale HTTP-only nginx-Konfiguration (für die ACME-Challenge).
5. Aktiviert die Site und lädt nginx neu.
6. Führt `certbot certonly --webroot` aus, um das Zertifikat zu holen.
7. Überschreibt die nginx-Konfiguration mit der vollständigen HTTPS-Version
   (HTTP → HTTPS-Weiterleitung + SSL-Block mit PHP-FPM-Unterstützung).
8. Lädt nginx erneut.

Das Skript kann problemlos ein zweites Mal für dieselbe Domain aufgerufen werden:
Der Symlink in `sites-enabled` wird nur einmal angelegt, und Certbot überspringt
die Erneuerung, wenn das Zertifikat noch gültig ist.

---

## Angelegte Dateien

| Datei | Beschreibung |
|---|---|
| `/etc/nginx/sites-available/<domain>` | nginx-Virtual-Host-Konfiguration |
| `/etc/nginx/sites-enabled/<domain>` | Symlink auf die obige Datei |
| `/etc/letsencrypt/live/<domain>/` | Zertifikatsdateien |

---

## Mitmachen

Fehlerberichte, Pull Requests und Vorschläge sind willkommen – siehe [TODO.md](TODO.md).
