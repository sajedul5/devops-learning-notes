#!/usr/bin/env bash
#
# Install Jenkins LTS + Temurin 17 JDK (Ubuntu/Debian). Safe to re-run.
#
# Usage: sudo ./jenkins.sh
#
# After install:
#   - Open http://<server-ip>:8080 and unlock with the initial admin password:
#       sudo cat /var/lib/jenkins/secrets/initialAdminPassword
#   - Create your own admin user, then put Jenkins behind HTTPS (../ssl/ssl.sh,
#     APP_PORT=8080). Do not leave 8080 open to the whole internet.
#
set -Eeuo pipefail

[[ $EUID -eq 0 ]] || { echo "Please run as root (sudo $0)" >&2; exit 1; }

apt-get update -y
apt-get install -y wget curl gpg ca-certificates
install -d -m 0755 /etc/apt/keyrings

# --- Java (Jenkins needs a JDK) -------------------------------------------------
if ! java -version 2>&1 | grep -q '17.*Temurin'; then
  echo "Temurin 17 JDK not found. Installing..."
  wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
    | gpg --dearmor --yes -o /etc/apt/keyrings/adoptium.gpg
  codename=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release)
  echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb ${codename} main" \
    > /etc/apt/sources.list.d/adoptium.list
  apt-get update -y
  apt-get install -y temurin-17-jdk
  java --version
else
  echo "Temurin 17 JDK is already installed. Skipping."
fi

# --- Jenkins ----------------------------------------------------------------------
if ! dpkg -s jenkins >/dev/null 2>&1; then
  echo "Jenkins not found. Installing..."
  # Jenkins rotates its repository signing key periodically. If "apt-get update"
  # reports NO_PUBKEY / EXPKEYSIG, get the current key URL from
  # https://pkg.jenkins.io/debian-stable/
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    -o /etc/apt/keyrings/jenkins-keyring.asc
  echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list
  apt-get update -y
  apt-get install -y jenkins
else
  echo "Jenkins is already installed. Skipping."
fi

systemctl enable --now jenkins
systemctl --no-pager status jenkins | head -5
