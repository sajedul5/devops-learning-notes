#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Nginx is not installed, install it
if ! command -v nginx &> /dev/null; then
  apt update
  apt install -y nginx
fi

# Check if Certbot is already installed
if ! command -v certbot &> /dev/null; then
  apt install -y certbot python3-certbot-nginx
fi

read -p "Enter your domain name: " DOMAIN_NAME

CERT_PATH="/etc/letsencrypt/live/${DOMAIN_NAME}"

if [ -f "${CERT_PATH}/fullchain.pem" ] && [ -f "${CERT_PATH}/privkey.pem" ]; then
  echo "SSL certificate for ${DOMAIN_NAME} already exists. Skipping Certbot."
else
  certbot --nginx -d "${DOMAIN_NAME}" --cert-path "${CERT_PATH}/fullchain.pem" --key-path "${CERT_PATH}/privkey.pem"
fi


SITES_AVAILABLE="/etc/nginx/sites-available/"
SITES_ENABLED="/etc/nginx/sites-enabled/"

# Append ".conf" to the configuration file name
CONFIG_FILE="${DOMAIN_NAME}.conf"


if [ ! -f "${SITES_AVAILABLE}${CONFIG_FILE}" ]; then
  read -p "Enter the listen port for Nginx (default: 80): " LISTEN_PORT
  LISTEN_PORT=${LISTEN_PORT:-80}

  read -p "Enter the proxy_pass port: " PROXY_PASS_PORT

  echo "server {
    listen ${LISTEN_PORT};
    server_name ${DOMAIN_NAME};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${DOMAIN_NAME};

    # SSL configuration
    ssl_certificate ${CERT_PATH}/fullchain.pem;
    ssl_certificate_key ${CERT_PATH}/privkey.pem;

    # Enable OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8;

    # Configure HSTS to force HTTPS
    add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;

    location / {
        # Proxy_pass configuration to your backend application
        proxy_pass http://127.0.0.1:${PROXY_PASS_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;

        # Additional proxy settings
        # proxy_set_header X-Real-IP \$remote_addr;
        # proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        # proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Additional server configurations (e.g., error pages, access logs, etc.)
    error_page 404 /404.html;
    location = /404.html {
        root /usr/share/nginx/html;
        internal;
    }

    access_log /var/log/nginx/${DOMAIN_NAME}_access.log;
    error_log /var/log/nginx/${DOMAIN_NAME}_error.log;
}" > "${SITES_AVAILABLE}${CONFIG_FILE}"


  if [ -e "${SITES_ENABLED}default" ]; then
    unlink "${SITES_ENABLED}default"
    echo "Unlinked default Nginx configuration file."
  fi

  ln -s "${SITES_AVAILABLE}${CONFIG_FILE}" "${SITES_ENABLED}${CONFIG_FILE}"

  # Check Nginx configuration
  if nginx -t; then
    systemctl restart nginx
    echo "Nginx configuration file created, SSL setup is complete. Your site should now be accessible over HTTPS."
  else
    echo "Error: Nginx configuration test failed. Please check your Nginx configuration."
  fi
else
  echo "Error: The specified configuration file already exists in ${SITES_AVAILABLE}."
  exit 1
fi
