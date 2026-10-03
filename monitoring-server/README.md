# Monitoring: Prometheus + Node Exporter + Grafana

```
node_exporter (host metrics :9100) ──scrape──▶ Prometheus (:9090) ◀──query── Grafana (:3000)
```

## Install (Ubuntu/Debian VM)

```bash
sudo ./prometheus.sh      # Prometheus + Node Exporter as systemd services
sudo ./grafana.sh         # Grafana OSS from the official APT repo
```

Both scripts are idempotent (safe to re-run). Pin versions with env vars:
`sudo PROM_VERSION=3.1.0 NODE_EXPORTER_VERSION=1.8.2 ./prometheus.sh`.

## Access

Prometheus and Node Exporter **have no authentication**, so they listen on
`127.0.0.1` only. From your laptop:

```bash
ssh -L 9090:localhost:9090 -L 3000:localhost:3000 user@server
# then open http://localhost:9090/targets and http://localhost:3000
```

To expose Prometheus on the network anyway (lab VM behind a firewall):
`sudo PROM_LISTEN=0.0.0.0:9090 ./prometheus.sh`.

Grafana: log in with `admin` / `admin` and **set a new password immediately**.
Add a data source → Prometheus → URL `http://localhost:9090`. Import dashboard
**1860 (Node Exporter Full)** for host metrics.

## Adding scrape targets

```bash
sudo nano /etc/prometheus/prometheus.yml        # add a job under scrape_configs
promtool check config /etc/prometheus/prometheus.yml
sudo systemctl reload prometheus                # no restart needed
journalctl -u prometheus -f --no-pager          # logs
```

Example Jenkins job (requires the Jenkins *Prometheus metrics* plugin):

```yaml
  - job_name: jenkins
    metrics_path: /prometheus
    static_configs:
      - targets: ["<jenkins-ip>:8080"]
```

## What the script does for security
- Dedicated `prometheus` / `node_exporter` system users with no login shell.
- Downloads verified against the official `sha256sums.txt`.
- systemd sandboxing (`ProtectSystem=strict`, `NoNewPrivileges`, ...).
- The `--web.enable-lifecycle` API (unauthenticated `/-/quit`) is **not** enabled.
  Reloads use `systemctl reload` (SIGHUP) instead.
