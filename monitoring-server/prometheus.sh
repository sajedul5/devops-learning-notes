#!/usr/bin/env bash
#
# Install Prometheus + Node Exporter as hardened systemd services (Ubuntu/Debian).
#
# Usage:
#   sudo ./prometheus.sh
#   sudo PROM_VERSION=3.1.0 NODE_EXPORTER_VERSION=1.8.2 ./prometheus.sh
#   sudo PROM_LISTEN=0.0.0.0:9090 ./prometheus.sh   # expose UI on the network (see warning)
#
# Security defaults:
#   - Both services run as dedicated no-login system users.
#   - Downloads are verified against the official sha256 checksums.
#   - Prometheus and Node Exporter have NO authentication, so by default they only
#     listen on 127.0.0.1. Reach the UI with an SSH tunnel:
#         ssh -L 9090:localhost:9090 user@server   then open http://localhost:9090
#     If you set PROM_LISTEN=0.0.0.0:9090, firewall the port to trusted IPs only.
#   - The /-/reload and /-/quit "lifecycle" API is NOT enabled; reload config with
#     "systemctl reload prometheus" (sends SIGHUP) instead.
#
set -Eeuo pipefail

PROM_VERSION="${PROM_VERSION:-3.1.0}"
NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.8.2}"
PROM_LISTEN="${PROM_LISTEN:-127.0.0.1:9090}"
NODE_EXPORTER_LISTEN="${NODE_EXPORTER_LISTEN:-127.0.0.1:9100}"

die() { echo "ERROR: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die "Please run as root (sudo $0)"

case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *) die "Unsupported architecture: $(uname -m)" ;;
esac

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# download_verified <github-repo> <version> <name>  -> extracts into $WORKDIR
download_verified() {
  local repo=$1 version=$2 name=$3
  local tarball="${name}-${version}.linux-${ARCH}.tar.gz"
  local base="https://github.com/prometheus/${repo}/releases/download/v${version}"
  echo "Downloading ${tarball}..."
  curl -fsSL -o "${WORKDIR}/${tarball}" "${base}/${tarball}"
  curl -fsSL -o "${WORKDIR}/sha256sums-${name}.txt" "${base}/sha256sums.txt"
  # Verify integrity: protects against corrupted or tampered downloads.
  (cd "$WORKDIR" && grep " ${tarball}\$" "sha256sums-${name}.txt" | sha256sum -c -) \
    || die "Checksum verification failed for ${tarball}"
  tar -xzf "${WORKDIR}/${tarball}" -C "$WORKDIR"
}

create_system_user() {
  id -u "$1" >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin "$1"
}

# ----------------------------------------------------------------------------
# Prometheus
# ----------------------------------------------------------------------------
create_system_user prometheus
download_verified prometheus "$PROM_VERSION" prometheus
src="${WORKDIR}/prometheus-${PROM_VERSION}.linux-${ARCH}"

install -m 0755 "${src}/prometheus" "${src}/promtool" /usr/local/bin/
install -d -o prometheus -g prometheus -m 0750 /etc/prometheus /var/lib/prometheus

# Keep an existing config on re-runs; only seed a default one the first time.
if [[ ! -f /etc/prometheus/prometheus.yml ]]; then
  cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["${PROM_LISTEN/0.0.0.0/localhost}"]

  - job_name: node_exporter
    static_configs:
      - targets: ["${NODE_EXPORTER_LISTEN/0.0.0.0/localhost}"]

  # Example: scrape Jenkins (requires the Jenkins "Prometheus metrics" plugin).
  # - job_name: jenkins
  #   metrics_path: /prometheus
  #   static_configs:
  #     - targets: ["<jenkins-ip>:8080"]
EOF
  chown prometheus:prometheus /etc/prometheus/prometheus.yml
fi
promtool check config /etc/prometheus/prometheus.yml

cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus \\
  --storage.tsdb.retention.time=15d \\
  --web.listen-address=${PROM_LISTEN}
ExecReload=/bin/kill -HUP \$MAINPID

# systemd sandboxing: limit what the process can touch if it is ever compromised
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ReadWritePaths=/var/lib/prometheus

[Install]
WantedBy=multi-user.target
EOF

# ----------------------------------------------------------------------------
# Node Exporter (host metrics: CPU, memory, disk, network)
# ----------------------------------------------------------------------------
create_system_user node_exporter
download_verified node_exporter "$NODE_EXPORTER_VERSION" node_exporter
install -m 0755 "${WORKDIR}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}/node_exporter" /usr/local/bin/

cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter \\
  --collector.logind \\
  --web.listen-address=${NODE_EXPORTER_LISTEN}

NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now prometheus node_exporter
systemctl restart prometheus node_exporter

prometheus --version | head -1
node_exporter --version 2>&1 | head -1
echo
echo "Prometheus UI:   http://${PROM_LISTEN}  (targets page: /targets)"
echo "Node Exporter:   http://${NODE_EXPORTER_LISTEN}/metrics"
echo "Edit scrape targets in /etc/prometheus/prometheus.yml, then:"
echo "  promtool check config /etc/prometheus/prometheus.yml && systemctl reload prometheus"
echo "Logs: journalctl -u prometheus -f --no-pager"
