# Security Guide for DevOps Beginners

This repo is for learning, but labs often turn into real servers. Use the habits
below from day one, because they are much harder to pick up later.

---

## 1. Never commit secrets

**A secret pushed to GitHub is leaked, even if you delete it a minute later.**
Bots scan public repos for credentials within seconds, and git history keeps every
version of every file.

Secrets include passwords, API keys, tokens, private SSH keys (`id_rsa`), TLS keys
(`*.pem`, `*.key`), cloud credential JSON files, kubeconfigs, `.env` files and
Terraform state (`*.tfstate` stores resource attributes in plain text).

**How this repo handles them:**

| Where | Pattern used |
|---|---|
| `elk/` | `elk/.env` (git-ignored), created from `.env.example`. Compose and Logstash read `${ELASTIC_PASSWORD}` |
| `terraform/` | Application Default Credentials (`gcloud auth application-default login`). IDs go in `terraform.tfvars` (git-ignored) |
| `docker/simpleproject/` | Docker **secret file** `db/password.txt` (git-ignored), mounted at `/run/secrets/` |
| `bash_script/mini-project/` | `DB_PASSWORD` environment variable, sent to MySQL via stdin |
| `solutions/bitbucket-pipelines/` | Bitbucket-managed SSH keys and secured variables, never in YAML |
| `k8s/secrets/` | Dummy values for practice only. See the Kubernetes section below |

**Tooling:** this repo runs [gitleaks](https://github.com/gitleaks/gitleaks) in CI
(`.github/workflows/ci.yml`) and as an optional pre-commit hook:

```bash
pip install pre-commit && pre-commit install   # scans every commit before it's created
```

### If you already committed a secret
1. **Rotate it first.** Change the password or revoke the key or token. This is
   the only step that actually protects you.
2. Remove it from the code and load it from env, a file or a secret manager instead.
3. Optionally purge it from history with
   [`git filter-repo`](https://github.com/newren/git-filter-repo) and force-push.
   This rewrites history for everyone, and copies may already exist, which is why
   step 1 matters most.

> **Note for this repo:** earlier commits contained an Elasticsearch password in
> `elk/logstash.conf`, plus a personal GCP credential path and organization ID in
> `terraform/`. These are removed from the current code. Anyone reusing those
> values must rotate them. They still exist in git history.

---

## 2. Least privilege

Give every user, process and token only the access it needs.

- **Linux services** run as dedicated no-login users (`useradd --system --shell /usr/sbin/nologin`),
  as in `monitoring-server/prometheus.sh`.
- **Databases:** grant `ALL ON appdb.*`, never `ALL ON *.*`.
- **Docker group = root.** Anyone in the `docker` group can run
  `docker run -v /:/host` and own the machine. Never `chmod 666 /var/run/docker.sock`.
  Consider [rootless Docker](https://docs.docker.com/engine/security/rootless/).
- **CI/CD:** use a dedicated deploy user and keys scoped to one purpose.
- **Cloud:** don't use the Owner role or org-admin accounts for Terraform; create a
  service account with only the roles the code needs.

---

## 3. Don't expose what has no authentication

Many DevOps tools have **no login by default**: Prometheus, Node Exporter, Redis,
Elasticsearch (with security disabled), Docker's TCP socket, debugger ports and the
Flask/Werkzeug debugger.

- Bind them to `127.0.0.1` (Compose: `"127.0.0.1:9200:9200"`) and use an SSH tunnel:
  `ssh -L 9090:localhost:9090 user@server`.
- Don't publish ports a service only needs internally. Containers on the same
  Compose network reach each other by service name (see `docker/docker-compose/`).
- Put web UIs (Grafana, Jenkins, Kibana) behind HTTPS (`ssl/ssl.sh`) and firewall them.
- Cloud security groups: never allow `0.0.0.0/0` on SSH or admin ports.
- Never run `debug=True` (Flask) or open `9229` (Node inspector) on a server. A
  reachable debugger means remote code execution.

---

## 4. Containers

```dockerfile
FROM python:3.12-slim          # pin a supported version, never an EOL one
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
RUN useradd --system appuser
USER appuser                   # don't run as root
```

- Pin image versions (`nginx:1.27-alpine`, not `nginx:latest`) so builds are reproducible.
- Use small base images (`-slim`, `-alpine`, distroless) for a smaller attack surface.
- Scan images: `docker scout cves <image>` or `trivy image <image>`.
- Never bake secrets into images with `ENV` or `COPY .env`. They stay in the layers forever.
- Add a `.dockerignore` so `.git`, `.env` and keys never enter the build context.

---

## 5. Kubernetes

The hardened pod template used in `rnd/k8s/`:

```yaml
spec:
  automountServiceAccountToken: false    # app doesn't call the K8s API
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile: { type: RuntimeDefault }
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities: { drop: ["ALL"] }
    resources:                           # limits stop one pod starving the node
      requests: { cpu: 50m, memory: 64Mi }
      limits:   { cpu: 250m, memory: 128Mi }
```

- **Secrets are only base64-encoded**, not encrypted. Don't commit them; use
  `kubectl create secret`, Sealed Secrets, SOPS or External Secrets Operator.
- Avoid `hostPath`, `privileged: true`, `hostNetwork` and `hostPID` outside labs.
- `--kubelet-insecure-tls` (metrics-server) is for local clusters only.
- Use RBAC with namespaced Roles, NetworkPolicies to restrict pod-to-pod traffic, and
  [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
  (`restricted` level) on namespaces.
- Kubeconfig files are cluster-admin credentials: `chmod 600`, never commit.

---

## 6. Scripts that install things

- Start bash scripts with `set -Eeuo pipefail` so they stop on the first error.
- Quote variables (`"$1"`), and validate user input before writing it into config files
  (see the domain and port checks in `ssl/ssl.sh`).
- Verify downloads with checksums (`sha256sum -c`), as `prometheus.sh` does.
- Store APT keys in `/etc/apt/keyrings/` with `signed-by=`. `apt-key add` is
  deprecated and trusts the key for every repository.
- Make scripts idempotent (safe to re-run): check before creating, and use `>` rather
  than `>>` for config files.
- Prefer reading a script before piping it to `sh` (`curl ... | sh`).

---

## 7. Terraform

- Never commit `*.tfstate` or `*.tfvars` with real values. Use a remote backend
  (GCS/S3 with encryption and locking) for team work.
- Authenticate with ADC or workload identity, not key files in the repo.
- Run `terraform fmt`, `terraform validate` and a scanner such as
  [`checkov`](https://www.checkov.io/) or [`tfsec`/`trivy config`](https://github.com/aquasecurity/trivy).

---

## Reporting a problem in this repo

Found a security issue? Please open a GitHub issue **without** including the secret
itself, or contact the maintainer directly.
