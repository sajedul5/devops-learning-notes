#!/usr/bin/env python3
import subprocess

def run_command(command):
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return result.returncode, result.stdout, result.stderr

def install_nginx():
    return run_command(["apt", "update"])

def install_certbot():
    return run_command(["apt", "install", "-y", "certbot", "python3-certbot-nginx"])

def obtain_ssl_certificate(domain_name, cert_path):
    return run_command(["certbot", "--nginx", "-d", domain_name, "--cert-path", f"{cert_path}/fullchain.pem", "--key-path", f"{cert_path}/privkey.pem"])

def create_nginx_config(domain_name, listen_port, proxy_pass_port, cert_path):
    config_content = f"""
server {{
    listen {listen_port};
    server_name {domain_name};
    return 301 https://$host$request_uri;
}}

server {{
    listen 443 ssl;
    server_name {domain_name};

    # SSL configuration
    ssl_certificate {cert_path}/fullchain.pem;
    ssl_certificate_key {cert_path}/privkey.pem;

    # Enable OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8;

    # Configure HSTS to force HTTPS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {{
        # Proxy_pass configuration to your backend application
        proxy_pass http://127.0.0.1:{proxy_pass_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;

        # Additional proxy settings
        # proxy_set_header X-Real-IP $remote_addr;
        # proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # proxy_set_header X-Forwarded-Proto $scheme;
    }}

    # Additional server configurations (e.g., error pages, access logs, etc.)
    error_page 404 /404.html;
    location = /404.html {{
        root /usr/share/nginx/html;
        internal;
    }}

    access_log /var/log/nginx/{domain_name}_access.log;
    error_log /var/log/nginx/{domain_name}_error.log;
}}
"""
    return config_content

def main():
    # Check if script is run as root
    if not subprocess.run(["id", "-u"], stdout=subprocess.PIPE, text=True).stdout.strip() == "0":
        print("Please run as root")
        exit()

    # Check if Nginx is already installed
    if not run_command(["command", "-v", "nginx"])[0] == 0:
        # Nginx is not installed, install it
        install_nginx()

    # Check if Certbot is already installed
    if not run_command(["command", "-v", "certbot"])[0] == 0:
        # Certbot is not installed, install it
        install_certbot()

    # Prompt for user input
    domain_name = input("Enter your domain name: ")
    listen_port = input("Enter the listen port for Nginx (default: 80): ") or "80"
    proxy_pass_port = input("Enter the proxy_pass port: ")

    # Set the full path for the SSL certificate files
    cert_path = f"/etc/letsencrypt/live/{domain_name}"

    # Check if SSL certificate already exists
    if run_command(["test", "-f", f"{cert_path}/fullchain.pem"]) == 0 and run_command(["test", "-f", f"{cert_path}/privkey.pem"]) == 0:
        print(f"SSL certificate for {domain_name} already exists. Skipping Certbot.")
    else:
        # SSL certificate does not exist, obtain and install it
        obtain_ssl_certificate(domain_name, cert_path)

    # Set the full path for sites-available and sites-enabled
    sites_available = "/etc/nginx/sites-available/"
    sites_enabled = "/etc/nginx/sites-enabled/"

    # Append ".conf" to the configuration file name
    config_file = f"{domain_name}.conf"

    # Check if the Nginx configuration file exists in sites-available
    if run_command(["test", "!", "-f", f"{sites_available}{config_file}"]) == 0:
        # Create a new configuration file with user-specified ports
        config_content = create_nginx_config(domain_name, listen_port, proxy_pass_port, cert_path)
        with open(f"{sites_available}{config_file}", "w") as config_file:
            config_file.write(config_content)

        # Check if the default configuration
