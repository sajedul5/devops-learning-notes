#!/usr/bin/env bash
#
# Install Grafana OSS from the official APT repository (Ubuntu/Debian).
#
# Usage: sudo ./grafana.sh
#
# After install, open http://<server-ip>:3000 and log in with admin / admin.
# Grafana FORCES you to change that password on first login — do it right away,
# before exposing port 3000 to the internet. Better: put Grafana behind the
# HTTPS reverse proxy from ../ssl/ssl.sh (APP_PORT=3000).
#
set -Eeuo pipefail

[[ $EUID -eq 0 ]] || { echo "Please run as root (sudo $0)" >&2; exit 1; }

apt-get update
apt-get install -y apt-transport-https software-properties-common wget gpg

# Store the signing key in its own keyring and scope it to the Grafana repo only
# ("signed-by"). The old "apt-key add" trusted the key for EVERY repository and
# is deprecated.
install -d -m 0755 /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/grafana.gpg
chmod a+r /etc/apt/keyrings/grafana.gpg

# ">" (not ">>") so re-running the script does not add duplicate entries.
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
  > /etc/apt/sources.list.d/grafana.list

apt-get update
apt-get install -y grafana

# Start now and on every boot.
systemctl daemon-reload
systemctl enable --now grafana-server
systemctl --no-pager status grafana-server | head -5

echo
echo "Grafana is running on port 3000 — log in as admin/admin and change the password immediately."
echo "Add Prometheus as a data source with URL http://localhost:9090"
