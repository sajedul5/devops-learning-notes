# let's make sure that all the dependencies are installed
sudo apt-get install -y apt-transport-https software-properties-common
# Next, add the GPG key.
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
# Add this repository for stable releases.
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
# After you add the repository, update and install Garafana
sudo apt-get update
sudo apt-get -y install grafana

# To automatically start the Grafana after reboot, enable the service
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sudo systemctl status grafana-server
http://<ip>:3000