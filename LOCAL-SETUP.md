# Run Every Lab Locally

This guide shows how anyone can run the labs in this repo on their own computer
(macOS, Windows or Linux) for free, without breaking their laptop.

**The idea:** run Docker labs directly on your laptop, and run everything that
needs a Linux server or Kubernetes inside a **throwaway Ubuntu VM**. If you break
the VM, delete it and make a new one in two minutes.

```
┌──────────────────────── Your laptop ────────────────────────┐
│  Docker Desktop ─▶ docker/ labs, elk/, bash_script/          │
│                                                              │
│  ┌──────────── Ubuntu VM "devops-lab" (Multipass) ─────────┐ │
│  │ Docker + k3s ─▶ k8s/, helm_chart/, rnd/, nginx-test.yaml│ │
│  │ systemd      ─▶ monitoring-server/, jenkins/            │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
   Cloud / accounts needed ─▶ terraform/ (GCP), ssl/ (domain),
                              solutions/bitbucket-pipelines/ (Bitbucket + EC2)
```

---

## Where each lab runs

| Lab | Laptop (Docker Desktop) | Ubuntu VM | Needs cloud/account |
|---|:---:|:---:|:---:|
| `bash_script/` exercises | ✅ (macOS, Linux, WSL) | ✅ | |
| `bash_script/mini-project/` | | Rocky Linux VM (see [§7](#7-rocky-linux-vm-for-the-e-commerce-mini-project)) | |
| `docker/` | ✅ | ✅ | |
| `elk/` | ✅ (8 GB RAM+) | ✅ | |
| `k8s/`, `helm_chart/`, `rnd/` | k3d (alternative, [§4b](#4b-alternative-kubernetes-without-a-vm-k3d)) | ✅ **recommended** | |
| `monitoring-server/` | | ✅ | |
| `jenkins/` | | ✅ | |
| `ssl/` | | | public server + domain |
| `terraform/` | | | GCP account (free trial) |
| `solutions/bitbucket-pipelines/` | | | Bitbucket + AWS EC2 |
| `claude/` | ✅ | | Claude account |

**Hardware:** 4 CPU cores, 8 GB RAM (16 GB is comfortable), 40 GB free disk.

---

## 1. Install the tools (one time)

### macOS
```bash
# Homebrew: https://brew.sh
brew install --cask docker          # Docker Desktop. Open it once after install
brew install --cask multipass       # Ubuntu VMs
brew install git kubectl helm
```

### Windows 10/11
1. Enable WSL2: open PowerShell as Administrator → `wsl --install` → reboot.
2. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (enable *Use WSL 2 based engine*).
3. Install [Multipass](https://multipass.run/install) (uses Hyper-V or VirtualBox).
4. Run all commands in this guide from the **Ubuntu (WSL)** terminal.

### Linux (Ubuntu/Debian)
```bash
sudo snap install multipass
sudo snap install kubectl --classic && sudo snap install helm --classic
# Docker Engine: https://docs.docker.com/engine/install/ubuntu/
```

Check:
```bash
docker run --rm hello-world && multipass version && git --version
```

---

## 2. Get the code

```bash
git clone https://github.com/sajedul5/devops-learning-notes.git
cd devops-learning-notes
```

---

## 3. Laptop track: Docker, ELK, Bash

No VM needed. Each folder's README has the details.

```bash
# Docker basics
cd docker && docker build -t my-nginx . && docker run -d -p 8080:80 --name web my-nginx
open http://localhost:8080            # Windows/WSL: explorer.exe http://localhost:8080
docker rm -f web && cd ..

# Flask + Redis with Compose
cd docker/docker-compose && docker compose up -d --build && curl localhost:5050
docker compose down && cd ../..

# React + Node + MariaDB with Docker secrets
cd docker/simpleproject
openssl rand -base64 24 > db/password.txt
docker compose up -d --build           # first build takes a few minutes
open http://localhost:3000
docker compose down -v && cd ../..

# ELK stack (give Docker Desktop at least 6 GB RAM: Settings → Resources)
cd elk && cp .env.example .env
sed -i.bak "s|^ELASTIC_PASSWORD=.*|ELASTIC_PASSWORD=$(openssl rand -hex 16)|" .env && rm .env.bak
docker compose up -d
open http://localhost:5601             # user: elastic, password: see elk/.env
docker compose down -v && cd ..

# Bash exercises
bash bash_script/hello_world.sh
```

---

## 4. Ubuntu VM track: Kubernetes, Helm, monitoring, Jenkins

### 4a. Create the VM and install Docker + k3s

```bash
# On your laptop
multipass launch 24.04 --name devops-lab --cpus 4 --memory 6G --disk 40G
multipass shell devops-lab
```

You're now **inside the VM** (prompt `ubuntu@devops-lab`). Everything until §6
runs here.

```bash
git clone https://github.com/sajedul5/devops-learning-notes.git
cd devops-learning-notes

# Docker + single-node Kubernetes (k3s). Safe here: the VM is brand new.
sudo ./setup-docker-k3s.sh --yes
newgrp docker                       # use docker without sudo in this shell

kubectl get nodes                   # STATUS should be Ready
```

> **Apple Silicon Macs (M1–M4) and other ARM machines: run this once.**
> The repo's own images (`sajedul5/*`) and `polinux/stress` are built for
> x86-64 (amd64) only. Without emulation their pods fail with
> `exec format error`. Install QEMU emulation in the VM:
> ```bash
> sudo apt-get install -y qemu-user-static
> docker run --rm --platform linux/amd64 alpine uname -m   # should print x86_64
> ```
> Emulated images run a bit slower, which is fine for labs.

Find the VM's IP. You'll use it in your laptop's browser:
```bash
hostname -I | awk '{print $1}'     # e.g. 192.168.64.5
```

Smoke test:
```bash
kubectl apply -f nginx-test.yaml
kubectl rollout status deploy/nginx-test
curl -s localhost:30080 | grep title        # <title>Welcome to nginx!</title>
kubectl delete -f nginx-test.yaml
```

### 4b. Alternative: Kubernetes without a VM (k3d)

If you only want the Kubernetes labs and already run Docker Desktop, k3d runs k3s
inside Docker on your laptop. On Apple Silicon, Docker Desktop's built-in emulation
also runs the amd64-only images.

```bash
brew install k3d        # or: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d cluster create devops-lab \
  -p "8080:80@loadbalancer" \
  -p "32410:32410@server:0" -p "30080:30080@server:0"
kubectl get nodes
```
Then use `localhost` instead of the VM IP (ingress on `localhost:8080`).
Delete with `k3d cluster delete devops-lab`.

---

## 5. Running the Kubernetes labs

Follow [`k8s/README.md`](k8s/README.md) in order. Each folder's `.md` has the
commands. A typical lab:

```bash
cd ~/devops-learning-notes/k8s/deployments
cat deployment.md                    # read first
kubectl apply -f deployment.yaml
kubectl get pods -w                  # Ctrl-C to stop watching
kubectl delete -f deployment.yaml    # always clean up before the next lab
```

### How to reach your apps

k3s includes everything the labs need: **Traefik** (ingress), **ServiceLB**
(LoadBalancer services), **metrics-server** (autoscaling) and **local-path**
storage.

| Service type in the lab | Open from your laptop |
|---|---|
| `NodePort` (e.g. `k8s/nodePort/`, port 32410) | `http://<VM-IP>:32410` |
| `LoadBalancer` (e.g. `k8s/load-balancer/`, port 5000) | `http://<VM-IP>:5000` (see `kubectl get svc` → EXTERNAL-IP) |
| `ClusterIP` (internal only) | `kubectl port-forward svc/<name> 8080:<port> --address 0.0.0.0` → `http://<VM-IP>:8080` |
| `Ingress` with a host name | add `<VM-IP>  <host>` to your **laptop's** hosts file, then `http://<host>` |

Hosts file: macOS/Linux `/etc/hosts` (`sudo nano /etc/hosts`); Windows
`C:\Windows\System32\drivers\etc\hosts` (Notepad as Administrator).
The ingress labs use these host names:

```
<VM-IP>  test-shakil.com app.local api.local
```

### Notes for specific labs on k3s

| Lab | Note |
|---|---|
| `k8s/ingress/` | Skip `nginx-ingress-controller.yaml` and `default-http-backend-*`. k3s's built-in **Traefik** serves the Ingress. Apply `nginx-deployment.yaml`, `nginx-loadbalancer-service.yaml`, `nginx-ingress.yaml`, then open `http://test-shakil.com` |
| `k8s/scale-pods/`, `k8s/autoscaling/` | metrics-server is already installed. **Don't** apply `components.yaml`. Check with `kubectl top nodes` |
| `k8s/autoscaling/` | Watch scaling with `kubectl get hpa -w` while `load-test-pod.yaml` runs, then delete the load test |
| `k8s/volume/`, `k8s/statefulset/` | Work as-is. The StatefulSet's volume claims use k3s's default `local-path` storage |
| `k8s/k3s-install/`, `k8s/multi-k8s-cluster.md` | Need several VMs: `multipass launch 24.04 --name worker1 --cpus 2 --memory 2G` per node, and use the VM IPs in place of the placeholders |
| `k8s/secrets/` | Uses dummy values on purpose. Read the warning at the top of `secrets.yaml` |

### Helm charts
```bash
cd ~/devops-learning-notes
helm install hello helm_chart/helloworld
kubectl get svc hello-helloworld            # NodePort → http://<VM-IP>:<nodePort>
helm uninstall hello

helm install py helm_chart/py-app           # LoadBalancer on port 9001
curl http://localhost:9001/hello            # {"data":"Hello World"}
helm uninstall py
```

### Blue-green & canary (`rnd/`)
Follow [`rnd/README.md`](rnd/README.md). Add `app.local api.local` to your laptop's
hosts file (see above). Because k3s runs on Docker in this VM (`--docker`), you can
also build the images yourself and k3s uses them without pushing anywhere:
```bash
docker build -t sajedul5/devops:api-v1 rnd/app/api       # tag must match the manifest
```

---

## 6. Monitoring & Jenkins (inside the VM)

These scripts install system services, so run them in the VM, never on your laptop.

```bash
cd ~/devops-learning-notes

# Prometheus + Node Exporter. On a private local VM it's OK to listen on all
# interfaces so your laptop's browser can reach it.
sudo PROM_LISTEN=0.0.0.0:9090 ./monitoring-server/prometheus.sh
sudo ./monitoring-server/grafana.sh
sudo ./jenkins/jenkins.sh
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

| Tool | URL (from laptop) | Login |
|---|---|---|
| Prometheus | `http://<VM-IP>:9090/targets` | none |
| Grafana | `http://<VM-IP>:3000` | admin / admin → set a new password |
| Jenkins | `http://<VM-IP>:8080` | initial admin password above |

In Grafana add the data source `http://localhost:9090` and import dashboard **1860**.

---

## 7. Rocky Linux VM for the e-commerce mini-project

`bash_script/mini-project/e-commerce-deployment.sh` uses `yum` and `firewalld`
(RHEL family), so it needs a Rocky/Alma Linux VM instead of Ubuntu:

- **Any OS:** [Vagrant](https://developer.hashicorp.com/vagrant/install) + VirtualBox:
  `vagrant init generic/rocky9 && vagrant up && vagrant ssh`
- **Apple Silicon:** [UTM](https://mac.getutm.app/) with the Rocky Linux 9 ARM ISO.

Inside the VM:
```bash
sudo dnf install -y git
git clone https://github.com/sajedul5/devops-learning-notes.git && cd devops-learning-notes
export DB_PASSWORD="$(openssl rand -base64 18)"
export REPO_URL=https://github.com/kodekloudhub/learning-app-ecommerce.git
bash bash_script/mini-project/e-commerce-deployment.sh
```

---

## 8. Labs that need the cloud

| Lab | What you need | Free option |
|---|---|---|
| `terraform/` | GCP project + `gcloud` CLI | [GCP free trial](https://cloud.google.com/free). You can always run `terraform init && terraform validate` offline |
| `ssl/` | Public server + domain name (Let's Encrypt must reach port 80) | a free-tier VM + a free subdomain (e.g. DuckDNS) |
| `solutions/bitbucket-pipelines/` | Bitbucket repo + AWS EC2 | AWS free tier |

Remember to **destroy cloud resources when done** (`terraform destroy`, terminate VMs).

---

## 9. Reset, stop, delete

```bash
multipass stop devops-lab            # pause (frees RAM)
multipass start devops-lab
multipass delete devops-lab && multipass purge     # delete everything, start fresh
docker system prune -a               # laptop: reclaim disk from old images
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Pod status `CrashLoopBackOff` with `exec format error` in logs | amd64 image on an ARM machine. Install `qemu-user-static` (see §4a) |
| Pod stuck in `Pending` | `kubectl describe pod <name>` → read *Events*. Usually not enough CPU/RAM: give the VM more (`multipass set local.devops-lab.memory=8G` while stopped) |
| `ImagePullBackOff` | Typo in the image name, or Docker Hub rate limit. Wait or `docker login` in the VM |
| `kubectl: connection refused` | k3s not running: `sudo systemctl status k3s`, then `sudo systemctl restart k3s` |
| Can't open `http://<VM-IP>:port` | Check the service: `kubectl get svc`. Check the VM IP: `multipass list` |
| Ingress host name doesn't load | Hosts-file entry missing on your **laptop**, or a typo in the host |
| `docker: permission denied` in the VM | Run `newgrp docker` or log out and back in (`exit`, `multipass shell devops-lab`) |
| Elasticsearch exits right away | Not enough memory. Give Docker Desktop 6 GB+ |
| `apt-get` lock errors right after VM creation | Ubuntu is auto-updating. Wait 1–2 minutes and retry |
