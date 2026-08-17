# Claude Code CLI — End-to-End Setup Guide

Install, configure, authenticate, and share Claude Code CLI across macOS (MacBook),
bash/zsh shells, Ubuntu servers, and multi-user environments.

> Verified against **Claude Code v2.1.233** (macOS 15/Darwin 25.6, Ubuntu 22.04/24.04).
> Check your own version with `claude --version` and health with `claude doctor`.

---

## Table of Contents

1. [What you get](#1-what-you-get)
2. [Prerequisites](#2-prerequisites)
3. [Install on macOS (MacBook)](#3-install-on-macos-macbook)
4. [Shell setup (bash and zsh)](#4-shell-setup-bash-and-zsh)
5. [Install on Ubuntu / Linux / WSL](#5-install-on-ubuntu--linux--wsl)
6. [Authentication](#6-authentication)
7. [Multi-user CLI on a shared server](#7-multi-user-cli-on-a-shared-server)
8. [Connecting sessions and remote machines](#8-connecting-sessions-and-remote-machines)
9. [Configuration files and precedence](#9-configuration-files-and-precedence)
10. [MCP servers](#10-mcp-servers)
11. [Headless / CI / automation usage](#11-headless--ci--automation-usage)
12. [Updating and version pinning](#12-updating-and-version-pinning)
13. [Verification checklist](#13-verification-checklist)
14. [Troubleshooting](#14-troubleshooting)
15. [Uninstall](#15-uninstall)

---

## 1. What you get

`claude` is a terminal-native coding agent. After install you get:

| Surface | Command |
|---|---|
| Interactive session | `claude` |
| One-shot / scripted | `claude -p "prompt"` |
| Continue last session | `claude -c` |
| Health check | `claude doctor` |
| Auth management | `claude auth login` / `status` / `logout` |
| MCP servers | `claude mcp add|list|get|remove` |
| Background agents | `claude agents` |
| Self-update | `claude update` |

Config lives per-user in `~/.claude/` (settings, sessions, history, plugins).

---

## 2. Prerequisites

| Requirement | macOS | Ubuntu |
|---|---|---|
| Arch | Apple Silicon or Intel x64 | x86_64 or arm64 |
| Shell | zsh (default) or bash | bash (default) or zsh |
| Tools | `curl`, `git` | `curl`, `git`, `ca-certificates` |
| Node.js | Only for the npm install path (Node 18+) | Same |
| Network | HTTPS egress to `api.anthropic.com`, `claude.ai`, `statsig.anthropic.com` | Same |

Ubuntu base packages:

```bash
sudo apt-get update
sudo apt-get install -y curl git ca-certificates
```

---

## 3. Install on macOS (MacBook)

### 3.1 Native installer (recommended)

No Node.js required. Installs a self-contained binary to `~/.local/bin/claude`.

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Then make sure `~/.local/bin` is on your `PATH` (see [section 4](#4-shell-setup-bash-and-zsh)) and verify:

```bash
which claude          # → /Users/<you>/.local/bin/claude
claude --version      # → 2.1.233 (Claude Code)
claude doctor
```

### 3.2 Homebrew (alternative)

```bash
brew info --cask claude-code     # confirm the cask exists / see version
brew install --cask claude-code
```

Homebrew may lag behind the native installer. Do **not** mix Homebrew and the
native installer on the same machine — pick one, or `claude update` will fight
the package manager.

### 3.3 npm (alternative — needs Node.js 18+)

```bash
brew install node                             # if you don't have Node
npm install -g @anthropic-ai/claude-code
claude --version
```

If you started on npm and want to move to the native binary:

```bash
npm uninstall -g @anthropic-ai/claude-code
curl -fsSL https://claude.ai/install.sh | bash
hash -r                    # clear the shell's cached path to the old binary
which claude               # should now be ~/.local/bin/claude
```

### 3.4 Apple Silicon notes

- Install under your own user, never with `sudo`. A root-owned `~/.claude` breaks
  session writes and auto-update.
- If macOS Gatekeeper quarantines a binary you downloaded manually:
  `xattr -d com.apple.quarantine /path/to/claude`

---

## 4. Shell setup (bash and zsh)

The installer appends a PATH line to your shell rc file. If `claude: command not
found`, add it yourself.

### 4.1 zsh (macOS default)

```bash
cat >> ~/.zshrc <<'EOF'

# ---- Claude Code ----
export PATH="$HOME/.local/bin:$PATH"
EOF
source ~/.zshrc
```

### 4.2 bash (Ubuntu default, or bash on macOS)

```bash
cat >> ~/.bashrc <<'EOF'

# ---- Claude Code ----
export PATH="$HOME/.local/bin:$PATH"
EOF
source ~/.bashrc
```

On macOS, login shells read `~/.bash_profile`, not `~/.bashrc`. Chain them:

```bash
cat >> ~/.bash_profile <<'EOF'
[ -f ~/.bashrc ] && . ~/.bashrc
EOF
```

### 4.3 Useful shell additions

```bash
cat >> ~/.bashrc <<'EOF'

# Claude Code convenience
alias cc='claude'
alias ccc='claude -c'                 # continue last conversation
alias ccp='claude -p'                 # one-shot print mode
alias ccdr='claude --add-dir'         # grant an extra directory

# Optional: default model and effort for this shell
# export ANTHROPIC_MODEL=claude-opus-5
# export MAX_THINKING_TOKENS=  # leave unset unless you know you need it
EOF
```

### 4.4 Non-interactive shells (cron, systemd, CI)

`~/.bashrc` is skipped for non-interactive shells. Always use the absolute path
or export PATH inside the job:

```bash
# cron
0 * * * * PATH=$HOME/.local/bin:/usr/bin:/bin /home/alice/.local/bin/claude -p "..." >> /var/log/cc.log 2>&1
```

---

## 5. Install on Ubuntu / Linux / WSL

### 5.1 Native installer (recommended, per user)

```bash
sudo apt-get update && sudo apt-get install -y curl git ca-certificates
curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
claude --version
claude doctor
```

Add the PATH line to `~/.bashrc` permanently (see [4.2](#42-bash-ubuntu-default-or-bash-on-macos)).

### 5.2 npm path (if you already manage Node centrally)

```bash
# NodeSource LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g @anthropic-ai/claude-code
```

To avoid `sudo npm -g`, give npm a user-owned prefix:

```bash
npm config set prefix "$HOME/.npm-global"
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
npm install -g @anthropic-ai/claude-code
```

### 5.3 WSL (Ubuntu on Windows)

Install inside the WSL distro, not on Windows, and keep repos on the Linux
filesystem (`/home/...`, not `/mnt/c/...`) — `/mnt/c` file watching and
performance are poor.

```bash
# in WSL
curl -fsSL https://claude.ai/install.sh | bash
```

Native Windows install (PowerShell), for reference:

```powershell
irm https://claude.ai/install.ps1 | iex
```

### 5.4 Headless Ubuntu server (no browser)

Interactive `claude auth login` wants a browser. On a headless box use one of:

- **Long-lived token minted on your laptop** — `claude setup-token` locally,
  then export the token on the server (see [6.3](#63-long-lived-token-subscription)).
- **API key** — `export ANTHROPIC_API_KEY=sk-ant-...` (see [6.4](#64-api-key-usage-based-billing)).
- **SSH port forwarding** so the server's OAuth callback reaches your laptop browser:

```bash
ssh -L 54545:localhost:54545 alice@server   # forward the callback port
# then on the server:
claude auth login
```

### 5.5 Docker image (optional pattern)

```dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y curl git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash dev
USER dev
WORKDIR /home/dev
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/dev/.local/bin:${PATH}"
# Auth is injected at runtime, never baked into the image:
#   docker run -e ANTHROPIC_API_KEY=... -v $PWD:/work -w /work <image> claude -p "..."
ENTRYPOINT ["claude"]
```

Never bake credentials into an image layer.

---

## 6. Authentication

Credential resolution, first match wins:

1. `ANTHROPIC_API_KEY`
2. `ANTHROPIC_AUTH_TOKEN`
3. OAuth credentials from `claude auth login` (stored in `~/.claude/` / OS keychain)
4. Third-party provider env vars (Bedrock / Vertex / Foundry)

Check what is actually active:

```bash
claude auth status
```

> **Trap:** a stale exported `ANTHROPIC_API_KEY` silently overrides your OAuth
> login — including an *empty* `ANTHROPIC_API_KEY=""`. Truly `unset` it before
> relying on a browser login.

### 6.1 Interactive login (desktop / laptop)

```bash
claude auth login      # opens a browser
claude auth status
```

Or run `claude` and use `/login` inside the session.

### 6.2 Logout

```bash
claude auth logout
```

### 6.3 Long-lived token (subscription)

Best for servers, containers, and CI when you have a Claude subscription:

```bash
# on a machine with a browser
claude setup-token
# → prints a token; store it in your secrets manager
```

On the target machine:

```bash
export ANTHROPIC_AUTH_TOKEN='<token>'
claude auth status
```

### 6.4 API key (usage-based billing)

```bash
export ANTHROPIC_API_KEY='sk-ant-...'
```

Keep it out of shell history and rc files — read it from a secrets manager:

```bash
# ~/.bashrc
export ANTHROPIC_API_KEY="$(pass show anthropic/api-key 2>/dev/null)"
```

Or use `apiKeyHelper` in settings so the key is fetched on demand:

```json
{
  "apiKeyHelper": "/usr/local/bin/fetch-anthropic-key.sh"
}
```

### 6.5 Enterprise providers

```bash
# Amazon Bedrock
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1
# plus standard AWS credentials / instance role

# Google Vertex AI
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-east5
export ANTHROPIC_VERTEX_PROJECT_ID=my-gcp-project
gcloud auth application-default login
```

### 6.6 Common environment variables

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | API key auth (highest precedence) |
| `ANTHROPIC_AUTH_TOKEN` | Bearer token auth (`claude setup-token`) |
| `ANTHROPIC_BASE_URL` | Point at a proxy or gateway |
| `ANTHROPIC_MODEL` | Default model, e.g. `claude-opus-5`, `claude-sonnet-5`, `claude-haiku-4-5` |
| `ANTHROPIC_SMALL_FAST_MODEL` | Model for cheap background tasks |
| `CLAUDE_CONFIG_DIR` | Relocate `~/.claude` (useful for multi-account) |
| `CLAUDE_CODE_USE_BEDROCK` / `CLAUDE_CODE_USE_VERTEX` | Provider selection |
| `DISABLE_TELEMETRY` | Opt out of usage telemetry |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | Disable all non-essential network calls |
| `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` | Corporate proxy |

Current model IDs: `claude-opus-5` (most capable Opus), `claude-sonnet-5`
(balanced), `claude-haiku-4-5` (fastest/cheapest). Do not append date suffixes
to these IDs.

---

## 7. Multi-user CLI on a shared server

Goal: several engineers SSH into one Ubuntu box and each run `claude` with their
own identity, their own history, and shared access to project code.

### 7.1 Architecture rule

**One binary per user, one config per user, one shared code directory.**
Claude Code stores state in `$HOME/.claude`, so isolation follows from normal
Unix home directories. Never share a `~/.claude` between humans — sessions,
history, and credentials would collide.

```
/srv/projects/devops        ← shared repo, group-writable
/home/alice/.local/bin/claude   /home/alice/.claude/   ← Alice's install + state
/home/bob/.local/bin/claude     /home/bob/.claude/     ← Bob's install + state
/etc/claude-code/managed-settings.json   ← org policy (root-owned, read-only)
```

### 7.2 Create the users and shared group

```bash
sudo groupadd -f devs
sudo adduser --disabled-password --gecos "" alice
sudo adduser --disabled-password --gecos "" bob
sudo usermod -aG devs alice
sudo usermod -aG devs bob
```

Shared, group-writable project directory with inherited group ownership:

```bash
sudo mkdir -p /srv/projects
sudo chgrp -R devs /srv/projects
sudo chmod -R 2775 /srv/projects       # 2 = setgid → new files inherit group 'devs'
```

Make new files group-writable for each user:

```bash
echo 'umask 002' | sudo tee -a /etc/profile.d/devs-umask.sh
```

Git safety on a shared repo:

```bash
sudo -u alice git config --global --add safe.directory /srv/projects/devops
sudo -u bob   git config --global --add safe.directory /srv/projects/devops
```

### 7.3 Per-user install (recommended)

Each user runs, in their own SSH session:

```bash
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
claude --version
claude auth status
```

Advantages: independent updates, no root needed, no permission conflicts.

### 7.4 Shared system-wide binary (alternative)

Use when you want one audited version for everyone.

```bash
# install once as root into a shared location
sudo mkdir -p /opt/claude-code
sudo env HOME=/opt/claude-code bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
sudo ln -sf /opt/claude-code/.local/bin/claude /usr/local/bin/claude
sudo chmod -R a+rX /opt/claude-code
```

Then, for every user:

```bash
claude --version    # resolves via /usr/local/bin/claude
```

Config still lands in each user's `~/.claude` — that is what you want.
Disable per-user auto-update so users cannot mutate the shared binary
(see [7.7](#77-org-wide-policy-managed-settings)).

### 7.5 Per-user authentication

Each user authenticates as themselves. Never share tokens.

```bash
# Option A — each user logs in with SSH port forwarding from their laptop
ssh -L 54545:localhost:54545 alice@server
claude auth login

# Option B — each user exports their own token from your secrets manager
export ANTHROPIC_AUTH_TOKEN="$(vault kv get -field=token secret/claude/alice)"

# Option C — service accounts for automation only
export ANTHROPIC_API_KEY="$(vault kv get -field=key secret/claude/ci)"
```

Verify per user:

```bash
sudo -iu alice claude auth status
sudo -iu bob   claude auth status
```

Lock down home directories so users cannot read each other's credentials:

```bash
sudo chmod 700 /home/alice /home/bob
sudo chmod 700 /home/alice/.claude /home/bob/.claude
```

### 7.6 Multiple accounts for one user

Use `CLAUDE_CONFIG_DIR` to keep separate profiles (e.g. work vs personal):

```bash
alias claude-work='CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude'
alias claude-oss='CLAUDE_CONFIG_DIR="$HOME/.claude-oss"  claude'
```

Each profile has its own auth, settings, and session history.

### 7.7 Org-wide policy (managed settings)

Root-owned policy that users cannot override. This is the correct place for
security rules on a shared box.

- Linux: `/etc/claude-code/managed-settings.json`
- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`

```bash
sudo mkdir -p /etc/claude-code
sudo tee /etc/claude-code/managed-settings.json >/dev/null <<'JSON'
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "deny": [
      "Bash(sudo *)",
      "Bash(rm -rf /*)",
      "Bash(curl * | bash)",
      "Read(./.env)",
      "Read(./**/*.pem)",
      "Read(./**/id_rsa*)"
    ],
    "allow": [
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(kubectl get *)",
      "Bash(terraform plan)"
    ]
  },
  "env": {
    "ANTHROPIC_MODEL": "claude-opus-5",
    "DISABLE_TELEMETRY": "1"
  },
  "autoUpdates": false
}
JSON
sudo chmod 644 /etc/claude-code/managed-settings.json
```

Verify a user picks it up:

```bash
sudo -iu alice claude doctor
```

### 7.8 Per-user resource limits (optional but recommended)

Stop one agent run from starving the box:

```bash
sudo tee /etc/security/limits.d/90-devs.conf >/dev/null <<'EOF'
@devs  soft  nproc   512
@devs  hard  nproc   1024
@devs  soft  nofile  8192
@devs  hard  nofile  16384
EOF
```

With systemd-logind, cap CPU/memory per user slice:

```bash
sudo systemctl set-property user-$(id -u alice).slice CPUQuota=400% MemoryMax=8G
```

### 7.9 Multi-user checklist

- [ ] Each user has their own `$HOME` and `~/.claude` (mode 700)
- [ ] `claude --version` works for every user
- [ ] `claude auth status` shows the correct, distinct identity per user
- [ ] Shared project dir is `2775`, group `devs`, `umask 002` in place
- [ ] `git config --global --add safe.directory <repo>` done per user
- [ ] `managed-settings.json` present, root-owned, and reflected in `claude doctor`
- [ ] No credentials in `~/.bashrc`, shell history, or git
- [ ] Resource limits applied

---

## 8. Connecting sessions and remote machines

### 8.1 SSH + tmux (the durable pattern)

An agent run should survive a dropped SSH connection:

```bash
ssh alice@server
tmux new -s claude          # or: tmux attach -t claude
cd /srv/projects/devops
claude
# detach: Ctrl-b then d      reattach: tmux attach -t claude
```

Give everyone a named session convention (`claude-<user>-<project>`) so you can
find work in progress.

### 8.2 Background agents on one machine

```bash
claude --bg "run the test suite and summarize failures"   # start detached
claude agents                                             # list / manage
```

### 8.3 Talking to other sessions

From inside a session, `/agents` and the agent tooling let one session delegate
to another. To list reachable sessions on the same machine and message them, use
the in-session agent commands rather than a separate daemon — there is no port to
open and nothing to expose.

### 8.4 Cloud / cross-machine sessions

```bash
claude --cloud "investigate the flaky deploy job"     # create a cloud session
claude --cloud <session_id|claude.ai/code URL>        # attach to an existing one
```

Cloud sessions are tied to your account, so each user reaches only their own.
Useful when you want work to continue after your laptop sleeps.

### 8.5 IDE / desktop clients against the same repo

VS Code and JetBrains extensions, and the desktop app, authenticate with the
same per-user credentials and read the same `~/.claude` settings and project
`CLAUDE.md`. Nothing extra to configure once the CLI is working.

### 8.6 What *not* to do

- Do not run `claude` as root or as a shared service account for human work —
  you lose attribution and permission boundaries.
- Do not expose a shared `~/.claude` over NFS to multiple simultaneous users;
  session and lock files will corrupt.
- Do not put an API key in a world-readable file on a multi-user box.

---

## 9. Configuration files and precedence

Highest precedence wins:

| Order | Scope | Path |
|---|---|---|
| 1 | Enterprise policy | `/etc/claude-code/managed-settings.json` (Linux) · `/Library/Application Support/ClaudeCode/managed-settings.json` (macOS) |
| 2 | CLI flags | `--settings`, `--model`, `--add-dir`, … |
| 3 | Project local (git-ignored) | `<repo>/.claude/settings.local.json` |
| 4 | Project shared (committed) | `<repo>/.claude/settings.json` |
| 5 | User | `~/.claude/settings.json` |

Project context / instructions: `<repo>/CLAUDE.md` (committed) and
`~/.claude/CLAUDE.md` (personal, all projects).

Example user settings — `~/.claude/settings.json`:

```json
{
  "model": "claude-opus-5",
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(kubectl get *)",
      "Bash(docker ps)",
      "Bash(terraform plan)"
    ],
    "deny": [
      "Bash(terraform apply *)",
      "Bash(kubectl delete *)",
      "Read(./.env)"
    ]
  },
  "env": {
    "KUBECONFIG": "/home/alice/.kube/config"
  }
}
```

Example project settings — `<repo>/.claude/settings.json` (safe to commit):

```json
{
  "permissions": {
    "allow": [
      "Bash(make *)",
      "Bash(docker compose *)",
      "Bash(helm template *)"
    ],
    "deny": [
      "Read(./secrets/**)",
      "Read(./**/*.tfstate)"
    ]
  }
}
```

`.gitignore` additions for a shared repo:

```gitignore
.claude/settings.local.json
.claude/.credentials.json
```

---

## 10. MCP servers

MCP servers add tools (databases, issue trackers, monitoring) to a session.

```bash
# HTTP server
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

# HTTP with auth header
claude mcp add --transport http internal https://mcp.example.com/api/mcp \
  --header "Authorization: Bearer $TOKEN"

# stdio server with env vars
claude mcp add pg -e DATABASE_URL="$DATABASE_URL" -- npx -y @modelcontextprotocol/server-postgres

claude mcp list
claude mcp get sentry
claude mcp remove sentry
```

Scopes: `--scope local` (default, this machine+project), `--scope project`
(writes `.mcp.json`, shared with the team via git), `--scope user` (all your
projects). Project-scoped servers from `.mcp.json` require per-user approval on
first use, which is the intended safety gate on a shared repo.

Inside a session, `/mcp` shows connection status and handles OAuth for servers
that need it.

---

## 11. Headless / CI / automation usage

```bash
# one-shot, plain text out
claude -p "summarize the changes on this branch"

# structured output for scripting
claude -p "list failing tests as JSON" --output-format json | jq .

# stream events
claude -p "refactor this module" --output-format stream-json

# constrain tools explicitly in automation
claude -p "audit k8s manifests" \
  --allowed-tools "Read Grep Glob Bash(kubectl get *)" \
  --output-format json
```

CI example (GitHub Actions):

```yaml
- name: Claude review
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: |
    curl -fsSL https://claude.ai/install.sh | bash
    export PATH="$HOME/.local/bin:$PATH"
    claude -p "Review the diff on this PR for correctness bugs" \
      --output-format json > review.json
```

`--dangerously-skip-permissions` bypasses every permission prompt. Use it only in
an isolated sandbox with no credentials and no production network access.

---

## 12. Updating and version pinning

```bash
claude update                # check and install the latest
claude install stable        # install the stable channel build
claude install latest        # install the newest build
claude install 2.1.233       # pin a specific version
claude install --force       # reinstall over an existing install
```

For a shared server, pin a version and disable per-user auto-update via
`managed-settings.json` (`"autoUpdates": false`), then roll upgrades yourself:

```bash
sudo env HOME=/opt/claude-code /opt/claude-code/.local/bin/claude install 2.1.233
```

npm installs update with `npm install -g @anthropic-ai/claude-code@latest`.

---

## 13. Verification checklist

Run this on every machine after setup:

```bash
#!/usr/bin/env bash
set -u
echo "user:      $(whoami)"
echo "which:     $(command -v claude || echo MISSING)"
echo "version:   $(claude --version 2>&1)"
echo "config:    ${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
echo "perms:     $(stat -c '%a %U' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" 2>/dev/null \
                  || stat -f '%Lp %Su' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")"
echo "--- auth ---";   claude auth status
echo "--- doctor ---"; claude doctor
echo "--- smoke ---";  claude -p "reply with exactly: OK"
```

Expected: a version string, `~/.claude` owned by you at mode 700, an
authenticated identity, a clean doctor report, and `OK` from the smoke test.

---

## 14. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `claude: command not found` | `~/.local/bin` not on PATH | Add the export to `~/.bashrc` / `~/.zshrc`, then `source` it |
| Works interactively, fails in cron/systemd | rc files not read | Use the absolute path and set `PATH` in the job |
| Wrong account / unexpected billing | stale `ANTHROPIC_API_KEY` shadowing OAuth | `unset ANTHROPIC_API_KEY`, then `claude auth status` |
| `401` / auth errors | expired token or missing key | `claude auth login`, or refresh `ANTHROPIC_AUTH_TOKEN` |
| Permission denied writing `~/.claude` | installed with `sudo` earlier | `sudo chown -R $(id -u):$(id -g) ~/.claude` and reinstall as your user |
| Update fails on shared install | binary owned by root | Update as root in `/opt/claude-code`; set `"autoUpdates": false` for users |
| `dubious ownership` from git | shared repo, different owner | `git config --global --add safe.directory <repo>` |
| Files unreadable by teammates | wrong umask/group | `umask 002`, `chmod -R 2775`, `chgrp -R devs` |
| Network/TLS failures behind proxy | proxy not configured | Export `HTTPS_PROXY`, `NO_PROXY`; ensure `ca-certificates` installed |
| Slow on WSL | repo on `/mnt/c` | Move the repo to `/home/<user>/` |
| MCP server shows pending | project-scoped `.mcp.json` needs approval | Run `/mcp` in a session and approve |

Deeper diagnostics:

```bash
claude doctor
claude --debug -p "hello"                  # verbose
claude --debug api -p "hello"              # filter to API logs
claude --debug-file /tmp/cc.log -p "hello" # write logs to a file
```

---

## 15. Uninstall

```bash
# native install
rm -f ~/.local/bin/claude
rm -rf ~/.claude          # WARNING: deletes sessions, settings, history

# npm install
npm uninstall -g @anthropic-ai/claude-code

# Homebrew
brew uninstall --cask claude-code

# shared system install
sudo rm -f /usr/local/bin/claude
sudo rm -rf /opt/claude-code
sudo rm -rf /etc/claude-code
```

Also revoke any long-lived tokens you minted (`claude auth logout`, plus
revocation in the Anthropic Console for API keys).

---

## Quick reference

```bash
# macOS / Ubuntu install
curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"

# auth
claude auth login | claude auth status | claude setup-token

# run
claude                      # interactive
claude -c                   # continue
claude -p "prompt"          # one-shot
claude --add-dir ../other   # extra directory access

# manage
claude doctor | claude update | claude mcp list | claude agents
```
