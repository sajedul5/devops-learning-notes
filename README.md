# DevOps Learning Lab

A hands-on collection of DevOps exercises, runbooks and scripts covering Linux shell
scripting, Docker, Kubernetes, Helm, Terraform (GCP), CI/CD, monitoring and logging.
It started as a personal learning log. It's organized so **another beginner can
follow the same path** and pick up secure habits from the start.

> **Read [SECURITY.md](SECURITY.md) first.** It explains why the code here avoids
> hardcoded passwords, root containers and open ports, and how to do the same in
> your own projects.

---

## Learning path

Work through the folders roughly in this order. Each step builds on the previous one.

| # | Topic | Folder | What you'll learn |
|---|---|---|---|
| 1 | Linux shell scripting | [`bash_script/`](bash_script/) | variables, conditions, loops, functions, then a full [deployment script](bash_script/mini-project/e-commerce-deployment.sh) |
| 2 | Python basics | [`python/`](python/) | variables and data types |
| 3 | Docker | [`docker/`](docker/) | Dockerfiles, volumes, Compose, multi-container apps, Docker secrets |
| 4 | Kubernetes | [`k8s/`](k8s/) | pods → deployments → services → storage → scaling → deployment strategies ([index](k8s/README.md)) |
| 5 | Local cluster setup | [`setup-docker-k3s.sh`](setup-docker-k3s.sh), [`k8s/k3s-install/`](k8s/k3s-install/), [`k8s/multi-k8s-cluster.md`](k8s/multi-k8s-cluster.md) | single-node k3s; HA kubeadm cluster with keepalived |
| 6 | Helm | [`helm_chart/`](helm_chart/) | packaging apps as charts with secure defaults |
| 7 | Release strategies | [`rnd/`](rnd/) | blue-green and canary deployments with Traefik ingress |
| 8 | Infrastructure as Code | [`terraform/`](terraform/) | GCP VPC with modules and variables |
| 9 | CI/CD | [`jenkins/`](jenkins/), [`solutions/bitbucket-pipelines/`](solutions/bitbucket-pipelines/) | Jenkins install; deploy to EC2 over SSH |
| 10 | Monitoring | [`monitoring-server/`](monitoring-server/) | Prometheus, Node Exporter, Grafana |
| 11 | Logging | [`elk/`](elk/) | Elasticsearch, Logstash and Kibana with Docker Compose |
| 12 | TLS / reverse proxy | [`ssl/`](ssl/) | Nginx + Let's Encrypt in front of any app |
| — | Tooling | [`claude/`](claude/) | setting up the Claude Code CLI |

## Repository layout

```
.
├── bash_script/          # shell scripting exercises + mini-project
├── docker/               # Dockerfiles, compose examples, docker-install.sh
├── k8s/                  # one folder per Kubernetes concept (YAML + notes .md)
├── helm_chart/           # helloworld (nginx) and py-app charts
├── rnd/                  # Node.js frontend/API + blue-green & canary manifests
├── terraform/            # GCP: root module + network/ and folders/ modules
├── jenkins/              # Jenkins LTS install script
├── monitoring-server/    # Prometheus + Node Exporter + Grafana install scripts
├── elk/                  # ELK stack (docker compose)
├── ssl/                  # Nginx reverse proxy + Let's Encrypt script
├── solutions/            # CI/CD examples (Bitbucket Pipelines)
├── claude/               # Claude Code CLI setup guide
├── setup-docker-k3s.sh   # one-shot Docker + k3s installer for Ubuntu
├── nginx-test.yaml       # smoke-test deployment for a fresh cluster
└── SECURITY.md           # security guide — read this
```

## Quick start

```bash
git clone https://github.com/sajedul5/devops.git && cd devops

# 1. A throwaway Ubuntu VM with Docker + single-node Kubernetes (k3s).
#    WARNING: wipes any existing Docker/k3s data on that machine.
sudo ./setup-docker-k3s.sh

# 2. Smoke test the cluster.
kubectl apply -f nginx-test.yaml
curl http://localhost:30080
kubectl delete -f nginx-test.yaml

# 3. Then follow the learning path, e.g.:
cd k8s/pods && cat pod.md
```

Everything else is self-contained: each folder has a `README.md` or `*.md` notes
explaining the commands to run.

## Prerequisites

- A Linux VM (Ubuntu 22.04/24.04 recommended) or macOS with Docker Desktop.
  **Don't run the install scripts on your daily-use laptop.** Use a VM
  (Multipass, VirtualBox, a cloud free tier).
- `kubectl`, `helm`, `terraform` for the respective sections.
- A GCP project (free tier works) for `terraform/`.

## Conventions used in this repo

- **No secrets in git.** Copy the `*.example` file (`.env.example`,
  `terraform.tfvars.example`, `password.txt.example`) and fill in real values locally.
  Those files are git-ignored.
- **Scripts are safe to re-run**, start with `set -Eeuo pipefail`, and check for root.
- **Images are pinned** to specific versions; containers run as non-root where possible.
- **Admin ports bind to `127.0.0.1`.** Use an SSH tunnel to reach them remotely.

## Checks (CI)

Every push and PR runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

| Check | Tool |
|---|---|
| Leaked secrets | gitleaks |
| Shell script bugs | shellcheck (infra scripts) |
| Terraform format/validity | `terraform fmt -check`, `terraform validate` |
| Helm charts | `helm lint` |
| Kubernetes manifests | kubeconform |

Run the same checks locally before committing:

```bash
pip install pre-commit && pre-commit install
pre-commit run --all-files
```

## Official documentation

[Docker](https://docs.docker.com/) ·
[Kubernetes](https://kubernetes.io/docs/) ·
[k3s](https://docs.k3s.io/) ·
[Helm](https://helm.sh/docs/) ·
[Terraform](https://developer.hashicorp.com/terraform/docs) ·
[Jenkins](https://www.jenkins.io/doc/) ·
[Prometheus](https://prometheus.io/docs/introduction/overview/) ·
[Grafana](https://grafana.com/docs/grafana/latest/) ·
[Elastic](https://www.elastic.co/guide/index.html) ·
[OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html) ·
[Kubernetes Security Checklist](https://kubernetes.io/docs/concepts/security/security-checklist/)

## Contributing

Issues and PRs are welcome, especially fixes, clearer explanations and new labs.
Please keep each lab self-contained with a short `.md`, pin image versions, and never
commit credentials (the pre-commit hook will catch most of them).
