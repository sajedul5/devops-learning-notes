#!/usr/bin/env bash
set -Eeuo pipefail
RED='\033[0;31m';GRN='\033[0;32m';YLW='\033[1;33m';BLU='\033[0;34m';NC='\033[0m'
info(){ echo -e "${BLU}[INFO]${NC} $*"; }
warn(){ echo -e "${YLW}[WARN]${NC} $*"; }
ok(){ echo -e "${GRN}[ OK ]${NC} $*"; }
die(){ echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

usage(){
  cat <<'EOF'
Usage: setup-docker-k3s.sh [options]

Reinstalls Docker and a single-node K3s cluster on Ubuntu.
WARNING: removes any existing Docker/K3s install and ALL their data.

Options:
  -y, --yes        Skip the destructive-action confirmation prompt.
  -h, --help       Show this help.

Environment overrides (for reproducible builds):
  DOCKER_VERSION       apt version string to pin docker-ce/docker-ce-cli
                       (e.g. 5:26.1.0-1~ubuntu.24.04~noble). Default: latest.
  INSTALL_K3S_VERSION  K3s release to pin (e.g. v1.31.5+k3s1). Default: latest.
  K3S_USE_DOCKER       1 (default) runs K3s on Docker via cri-dockerd;
                       0 uses K3s's bundled containerd (leaner, recommended
                       unless you need the Docker daemon on-host).
EOF
}

ASSUME_YES=0
for arg in "${@:-}"; do
  case "$arg" in
    "") ;;
    -y|--yes) ASSUME_YES=1;;
    -h|--help) usage; exit 0;;
    *) usage; die "Unknown argument: $arg";;
  esac
done

[[ $EUID -eq 0 ]] || die "Run as root"

LOG=/var/log/setup-docker-k3s.log
exec > >(tee -a "$LOG") 2>&1
trap 'die "Failed at line $LINENO"' ERR
trap 'wait' EXIT   # let the tee child flush before we exit

. /etc/os-release
[[ "$ID" == ubuntu ]] || die "Ubuntu only"
case "$VERSION_ID" in
22.04|24.04|26.04) ;;
*) die "Supported: Ubuntu 22.04/24.04/26.04";;
esac

if [[ $ASSUME_YES -ne 1 ]]; then
  [[ -t 0 ]] || die "Refusing to run non-interactively without --yes (this WIPES existing Docker & K3s data)"
  warn "This will REMOVE any existing Docker and K3s install on this host,"
  warn "including all containers, images, volumes and cluster state."
  read -r -p "Type 'yes' to continue: " reply
  [[ "$reply" == yes ]] || die "Aborted by user"
fi

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
# known-good LTS codename if this release has no published dist yet. Probe the
# HTTP status so a transient network error fails loudly instead of silently
# pinning the wrong codename.
DOCKER_CODENAME="$VERSION_CODENAME"
release_url="https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/Release"
http_code=$(curl -sSL --retry 3 --retry-delay 2 --max-time 20 -o /dev/null -w '%{http_code}' "$release_url" || echo 000)
case "$http_code" in
  200) ;;
  404) info "Docker repo has no '${VERSION_CODENAME}' dist yet; falling back to 'noble' (24.04)"
       DOCKER_CODENAME="noble";;
  *)   die "Could not reach Docker apt repo (HTTP $http_code); check network/proxy";;
esac
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${DOCKER_CODENAME} stable" >/etc/apt/sources.list.d/docker.list
apt-get update -y

# Optionally pin Docker for reproducible builds (DOCKER_VERSION env var).
docker_pkgs=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
if [[ -n "${DOCKER_VERSION:-}" ]]; then
  info "Pinning Docker to '${DOCKER_VERSION}'"
  docker_pkgs=(docker-ce="$DOCKER_VERSION" docker-ce-cli="$DOCKER_VERSION" containerd.io docker-buildx-plugin docker-compose-plugin)
fi
apt-get install -y "${docker_pkgs[@]}"
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
# Runtime: Docker (cri-dockerd) by default; K3S_USE_DOCKER=0 uses bundled containerd.
k3s_exec="--write-kubeconfig-mode 600"
if [[ "${K3S_USE_DOCKER:-1}" == 1 ]]; then
  k3s_exec+=" --docker"
else
  info "Using K3s bundled containerd (K3S_USE_DOCKER=0)"
fi
[[ -n "${INSTALL_K3S_VERSION:-}" ]] && info "Pinning K3s to '${INSTALL_K3S_VERSION}'"
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="${INSTALL_K3S_VERSION:-}" INSTALL_K3S_EXEC="$k3s_exec" sh -

mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config

# Also give the sudo user a usable kubeconfig (root's is mode 600, unreadable by them).
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
  user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  if [[ -n "$user_home" ]]; then
    install -d -m0700 -o "$SUDO_USER" -g "$SUDO_USER" "$user_home/.kube"
    install -m0600 -o "$SUDO_USER" -g "$SUDO_USER" /etc/rancher/k3s/k3s.yaml "$user_home/.kube/config"
    info "Wrote kubeconfig to $user_home/.kube/config for '$SUDO_USER'"
  fi
fi

info "Waiting for API server..."
api_up=0
for i in {1..60}; do
 if kubectl get nodes >/dev/null 2>&1; then api_up=1; break; fi
 sleep 5
done
[[ $api_up -eq 1 ]] || die "API server did not become reachable within 5 minutes"

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
