# Bitbucket Pipelines → EC2 (Docker Compose) deployment

Deploys a Dockerized app to an EC2 instance over SSH whenever `main` changes.

```
git push (main) ──▶ Bitbucket Pipeline ──scp/ssh──▶ EC2: docker compose up -d
```

## Prerequisites
- An EC2 instance with Docker + the Compose plugin installed
  (see [`../../setup-docker-k3s.sh`](../../setup-docker-k3s.sh) or [`../../docker/docker-install.sh`](../../docker/docker-install.sh)).
- Security group allows SSH (22) **only from Bitbucket's IP ranges or your VPN**, not `0.0.0.0/0`.
- A `docker-compose.yml` for your app in the repository.

## Setup

1. **Create a deploy user on the server** (don't deploy as `root` or `ec2-user`):
   ```bash
   sudo useradd -m -s /bin/bash deploy
   sudo usermod -aG docker deploy      # note: docker group == root-equivalent
   sudo mkdir -p /opt/myapp && sudo chown deploy: /opt/myapp
   ```
2. **SSH key** — *Repository settings → Pipelines → SSH keys → Generate keys*.
   Copy the **public** key into `/home/deploy/.ssh/authorized_keys`.
   Bitbucket keeps the private key and injects it into builds; you never paste a
   private key into a variable or a file.
3. **Known hosts** — on the same page, enter the server host, click *Fetch*, and
   verify the fingerprint matches `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`
   on the server. This protects against man-in-the-middle attacks.
4. **Repository variables** — `DEPLOY_HOST`, `DEPLOY_USER` (=`deploy`), `DEPLOY_PATH` (=`/opt/myapp`).
   Mark anything sensitive as **Secured** so it's masked in logs.
5. Copy [`bitbucket-pipelines.yml`](bitbucket-pipelines.yml) to your repo root, replace
   `./your-docker-files/*` with your files, commit and push to `main`.

## Security checklist
- [ ] No private keys, passwords or tokens in the YAML or the repo.
- [ ] Host key pinned through *Known hosts* (no `ssh-keyscan` inside the build).
- [ ] Dedicated, least-privilege deploy user.
- [ ] Only `main` deploys to production; use the `deployment:` environment for approvals/restrictions.
- [ ] App secrets live on the server in a `.env` file (mode `600`) or a secrets manager, never in git.
