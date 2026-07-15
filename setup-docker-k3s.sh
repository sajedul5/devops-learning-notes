#!/usr/bin/env bash
set -Eeuo pipefail
LOG=/var/log/setup-docker-k3s.log
exec > >(tee -a "$LOG") 2>&1
RED='\033[0;31m';GRN='\033[0;32m';YLW='\033[1;33m';BLU='\033[0;34m';NC='\033[0m'
info(){ echo -e "${BLU}[INFO]${NC} $*"; }
ok(){ echo -e "${GRN}[ OK ]${NC} $*"; }
die(){ echo -e "${RED}[FAIL]${NC} $*"; exit 1; }
trap 'die "Failed at line $LINENO"' ERR
trap 'wait' EXIT   # let the tee child flush before we exit
[[ $EUID -eq 0 ]] || die "Run as root"

. /etc/os-release
[[ "$ID" == ubuntu ]] || die "Ubuntu only"
case "$VERSION_ID" in
22.04|24.04|26.04) ;;
*) die "Supported: Ubuntu 22.04/24.04/26.04";;
esac

info "Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get full-upgrade -y
apt-get autoremove -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common

info "Removing old Docker..."
systemctl stop docker containerd 2>/dev/null || true
apt-get remove -y docker docker.io docker-compose docker-compose-v2 docker-ce docker-ce-cli containerd.io runc || true
rm -rf /var/lib/docker /var/lib/containerd /etc/docker /etc/containerd
rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/keyrings/docker.gpg

install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Docker's apt repo lags brand-new Ubuntu releases; fall back to the latest
# known-good LTS codename if this release has no published dist yet.
DOCKER_CODENAME="$VERSION_CODENAME"
if ! curl -fsSL "https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/Release" -o /dev/null; then
  info "Docker repo has no '${VERSION_CODENAME}' dist yet; falling back to 'noble' (24.04)"
  DOCKER_CODENAME="noble"
fi
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${DOCKER_CODENAME} stable" >/etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
docker run --rm hello-world >/dev/null
# Let the human who ran sudo use docker without sudo (takes effect on next login).
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
  usermod -aG docker "$SUDO_USER"
  info "Added '$SUDO_USER' to the docker group (re-login to take effect)"
fi
ok "Docker installed"

info "Removing old K3s..."
/usr/local/bin/k3s-uninstall.sh 2>/dev/null || true
/usr/local/bin/k3s-agent-uninstall.sh 2>/dev/null || true
rm -rf /etc/rancher /var/lib/rancher /var/lib/kubelet ~/.kube

info "Installing K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 600 --docker" sh -

mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config

info "Waiting for API server..."
for i in {1..60}; do
 if kubectl get nodes >/dev/null 2>&1; then break; fi
 sleep 5
done

info "Waiting for node to become Ready..."
kubectl wait --for=condition=Ready node --all --timeout=300s

kubectl get nodes
kubectl get pods -A

echo
ok "Docker version: $(docker --version)"
ok "Compose: $(docker compose version)"
ok "K3s: $(k3s --version | head -1)"
ok "kubectl: $(kubectl version --client -o yaml 2>/dev/null | awk '/gitVersion:/{print $2; exit}' || true)"
ok "Setup complete."
