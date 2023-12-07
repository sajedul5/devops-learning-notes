# To create a system user or system account, run the following command
sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false prometheus


# wget command to download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz


# extract all Prometheus files from the archive
tar -xvf prometheus-2.47.1.linux-amd64.tar.gz

# need a folder for Prometheus configuration files
sudo mkdir -p /data /etc/prometheus
# let's change the directory to Prometheus and move some files
cd prometheus-2.47.1.linux-amd64/
#  let's move the Prometheus binary and a promtool to the /usr/local/bin/. promtool is used to check configuration files and Prometheus rules
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/prometheus.yml
# To avoid permission issues, you need to set the correct ownership for the /etc/prometheus/ and data directory
sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
prometheus --version
prometheus --help


# need to create a Systemd unit configuration file
sudo vim /etc/systemd/system/prometheus.service

# Prometheus.service
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
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target

# To automatically start the Prometheus after reboot, run enable.
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus
# If you have any issues, check logs with journalctl
journalctl -u prometheus -f --no-pager

# let's create a system user for Node Exporter by running the following command

sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false node_exporter

# wget command to download the binary

wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz

# Extract the node exporter from the archive
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz

# Move binary to the /usr/local/bin
sudo mv \
  node_exporter-1.6.1.linux-amd64/node_exporter \
  /usr/local/bin/

# delete node_exporter archive and a folder
rm -rf node_exporter*

# 
node_exporter --version
node_exporter --help

# create a similar systemd unit file
sudo vim /etc/systemd/system/node_exporter.service

# node_exporter.service
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
ExecStart=/usr/local/bin/node_exporter \
    --collector.logind

[Install]
WantedBy=multi-user.target

# To automatically start the Node Exporter after reboot, enable the service
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
# If you have any issues, check logs with journalctl
journalctl -u node_exporter -f --no-pager


# To create a static target, you need to add job_name with static_configs
sudo vim /etc/prometheus/prometheus.yml

# prometheus.yml
  - job_name: node_export
    static_configs:
      - targets: ["localhost:9100"]
# Before, restarting check if the config is valid
promtool check config /etc/prometheus/prometheus.yml
# Then, you can use a POST request to reload the config
curl -X POST http://localhost:9090/-/reload
http://<ip>:9090/targets


#  To create a static target like jenkins, K8s cluster etc
sudo vim /etc/prometheus/prometheus.yml

  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['<jenkins-ip>:8080']
# Before, restarting check if the config is valid.
promtool check config /etc/prometheus/prometheus.yml

# Then, you can use a POST request to reload the config.
curl -X POST http://localhost:9090/-/reload


