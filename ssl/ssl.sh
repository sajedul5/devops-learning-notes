#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Check if Nginx is already installed
if ! command -v nginx &> /dev/null; then
  # Nginx is not installed, install it
  apt update
  apt install -y nginx
fi

# Check if Certbot is already installed
if ! command -v certbot &> /dev/null; then
  # Certbot is not installed, install it
  apt install -y certbot python3-certbot-nginx
fi

# Prompt for the domain name
read -p "Enter your domain name: " DOMAIN_NAME

# Set the full path for the SSL certificate files
CERT_PATH="/etc/letsencrypt/live/${DOMAIN_NAME}"

# Check if SSL certificate already exists
if [ -f "${CERT_PATH}/fullchain.pem" ] && [ -f "${CERT_PATH}/privkey.pem" ]; then
  echo "SSL certificate for ${DOMAIN_NAME} already exists. Skipping Certbot."
else
  # SSL certificate does not exist, obtain and install it
  certbot --nginx -d "${DOMAIN_NAME}" --cert-path "${CERT_PATH}/fullchain.pem" --key-path "${CERT_PATH}/privkey.pem"
fi

# Set the full path for sites-available and sites-enabled
SITES_AVAILABLE="/etc/nginx/sites-available/"
SITES_ENABLED="/etc/nginx/sites-enabled/"

# Append ".conf" to the configuration file name
CONFIG_FILE="${DOMAIN_NAME}.conf"

# Check if the Nginx configuration file exists in sites-available
if [ ! -f "${SITES_AVAILABLE}${CONFIG_FILE}" ]; then
  # Prompt for the listen port
  read -p "Enter the listen port for Nginx (default: 80): " LISTEN_PORT
  LISTEN_PORT=${LISTEN_PORT:-80}

  # Prompt for the proxy_pass port
  read -p "Enter the proxy_pass port: " PROXY_PASS_PORT

  # Create a new configuration file with user-specified ports
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

  # Check if the default configuration file is in sites-enabled and unlink it
  if [ -e "${SITES_ENABLED}default" ]; then
    unlink "${SITES_ENABLED}default"
    echo "Unlinked default Nginx configuration file."
  fi

  # Create a symbolic link in sites-enabled
  ln -s "${SITES_AVAILABLE}${CONFIG_FILE}" "${SITES_ENABLED}${CONFIG_FILE}"

  # Check Nginx configuration
  if nginx -t; then
    # Restart Nginx if configuration test is successful
    systemctl restart nginx
    echo "Nginx configuration file created, SSL setup is complete. Your site should now be accessible over HTTPS."
  else
    # Configuration test failed, inform the user
    echo "Error: Nginx configuration test failed. Please check your Nginx configuration."
  fi
else
  # Configuration file already exists
  echo "Error: The specified configuration file already exists in ${SITES_AVAILABLE}."
  exit 1
fi
