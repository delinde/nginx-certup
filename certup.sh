#!/bin/bash
set -e

# Farben
G=$'\033[0;32m'   # grün  – Rückmeldungen, Erfolg
Y=$'\033[1;33m'   # gelb  – Vorschläge, Fragen
RO=$'\033[0;31m'  # rot   – Fehlermeldungen
R=$'\033[0m'      # reset

# Root-Rechte sicherstellen – ggf. automatisch mit sudo neu starten
if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

# ---------------------------------------------------------------
echo ""
echo "=== Dies ist zert.sh"
echo "=== Ziel: HTTPS mit dem richtigen Let's-Encrypt-Zertifikat in nginx einrichten."
echo ""
# ---------------------------------------------------------------

# 1. Domain
read -e -p "${Y}Domain (z.B. example.com): ${R}" -i "$1" DOMAIN

if [[ -z "$DOMAIN" ]]; then
    echo "${RO}Fehler: Keine Domain eingegeben.${R}" >&2
    exit 1
fi

# 2. Webroot – automatisch den wahrscheinlichsten Ordner suchen
detect_webroot() {
    local domain="$1"
    local candidates=(
        "/home/www/${domain}/html"
        "/var/www/${domain}/html"
        "/var/www/${domain}/public_html"
        "/var/www/${domain}/public"
        "/srv/www/${domain}/html"
    )
    for path in "${candidates[@]}"; do
        if [[ -d "$path" ]]; then
            echo "$path"
            return
        fi
    done
    echo "${candidates[0]}"   # Standardvorschlag, auch wenn noch nicht vorhanden
}

WEBROOT_DEFAULT=$(detect_webroot "$DOMAIN")
read -e -p "${Y}Webroot: ${R}" -i "$WEBROOT_DEFAULT" WEBROOT
WEBROOT="${WEBROOT:-$WEBROOT_DEFAULT}"

# 3. E-Mail-Adresse
echo ""
echo "Let's-Encrypt-Zertifikate laufen nach 90 Tagen ab und werden in der Regel"
echo "selbsttätig erneuert – die Angabe einer E-Mail-Adresse ist dafür nicht erforderlich."
echo "Empfohlen ist sie dennoch: Sie erhalten dann eine Erinnerung, falls die"
echo "automatische Erneuerung einmal ausbleiben sollte."
echo "(Feld einfach leer lassen = kein Problem, solange der Certbot-Dienst läuft.)"
read -e -p "${Y}E-Mail-Adresse: ${R}" -i "${CERTBOT_EMAIL:-}" EMAIL
echo ""
if [[ -n "$EMAIL" ]]; then
    EMAIL_OPT="--email $EMAIL"
    echo "${G}  → Ablauf-Erinnerungen werden gesendet an: $EMAIL${R}"
else
    EMAIL_OPT="--register-unsafely-without-email"
    echo "  → Kein E-Mail – die selbsttätige Erneuerung läuft trotzdem."
fi

# 4. Zusammenfassung + Bestätigung
echo ""
echo "──────────────────────────────────────────────"
echo "  Domain   : $DOMAIN"
echo "  Webroot  : $WEBROOT"
echo "  E-Mail   : ${EMAIL:-keine}"
echo "──────────────────────────────────────────────"
echo ""
echo "Das Skript wird jetzt:"
echo "  1. Eine nginx-Konfiguration für $DOMAIN schreiben"
echo "  2. Ein Let's-Encrypt-Zertifikat beantragen"
echo "  3. nginx für HTTPS neu laden"
echo ""
read -e -p "${Y}Fortfahren? [J/n]: ${R}" -i "J" CONFIRM
if [[ ! "$CONFIRM" =~ ^[Jj]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

# Variablen
CONF_AVAIL="/etc/nginx/sites-available/${DOMAIN}"
CONF_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"
ACME_ROOT="/var/www/html"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"

# 5. Webroot prüfen
if [[ ! -d "$WEBROOT" ]]; then
    echo "" >&2
    echo "${RO}Fehler: Verzeichnis $WEBROOT existiert nicht.${R}" >&2
    echo "${RO}Bitte legen Sie den Ordner zuerst an und rufen Sie das Skript erneut auf.${R}" >&2
    exit 1
fi

# 6. HTTP-only Config schreiben (für ACME-Challenge)
echo ""
echo "${G}→ Schreibe nginx-Konfiguration (HTTP) ...${R}"
cat > "$CONF_AVAIL" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root ${ACME_ROOT};
    }

    location / {
        root ${WEBROOT};
    }
}
EOF

# 7. Site aktivieren
if [[ ! -L "$CONF_ENABLED" ]]; then
    ln -s "$CONF_AVAIL" "$CONF_ENABLED"
fi

nginx -t
systemctl reload nginx
echo "${G}→ nginx geladen (HTTP).${R}"

# 8. Zertifikat holen
echo ""
echo "${G}→ Certbot beantragt das Zertifikat bei Let's Encrypt ...${R}"
echo "  (Ihr Server muss über Port 80 aus dem Internet erreichbar sein.)"
echo ""
certbot certonly --webroot -w "$ACME_ROOT" -d "$DOMAIN" \
    --non-interactive --agree-tos $EMAIL_OPT

# 9. Vollständige Config (HTTP-Redirect + HTTPS) schreiben
echo ""
echo "${G}→ Schreibe nginx-Konfiguration (HTTPS) ...${R}"
cat > "$CONF_AVAIL" <<'EOF2'
# HTTP -> HTTPS Redirect
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    location /.well-known/acme-challenge/ {
        root ACME_PLACEHOLDER;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name DOMAIN_PLACEHOLDER;

    ssl_certificate CERT_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key CERT_PLACEHOLDER/privkey.pem;

    root WEBROOT_PLACEHOLDER;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }
}
EOF2

sed -i \
    -e "s|DOMAIN_PLACEHOLDER|${DOMAIN}|g" \
    -e "s|ACME_PLACEHOLDER|${ACME_ROOT}|g" \
    -e "s|CERT_PLACEHOLDER|${CERT_DIR}|g" \
    -e "s|WEBROOT_PLACEHOLDER|${WEBROOT}|g" \
    "$CONF_AVAIL"

nginx -t
systemctl reload nginx

echo ""
echo "${G}══════════════════════════════════════════════${R}"
echo "${G}  Fertig!  https://${DOMAIN}  ist jetzt aktiv.${R}"
echo ""
echo "  Bitte testen:"
echo "${Y}    http://${DOMAIN}${R}   → sollte auf HTTPS weiterleiten"
echo "${Y}    https://${DOMAIN}${R}  → sollte Ihre Seite zeigen"
echo "${G}══════════════════════════════════════════════${R}"
echo ""
