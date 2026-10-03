# Docker Labs

| Folder / file | What it shows |
|---|---|
| [`docker-install.sh`](docker-install.sh) | install Docker from Ubuntu's repo (see the docker-group warning inside) |
| [`Dockerfile`](Dockerfile) + `index.html` | the smallest useful image: static site on `nginx:alpine` |
| [`cmd.txt`](cmd.txt) | volume commands |
| [`python-docker/`](python-docker/) | Flask API image, run as a non-root user |
| [`docker-compose/`](docker-compose/) | Flask + Redis with Compose ([commands](docker-compose/cmd.md)) |
| [`simpleproject/`](simpleproject/) | React + Node + MariaDB with networks and **Docker secrets** ([guide](simpleproject/Readme.md)) |

## Dockerfile checklist (applied in this folder)
1. Pin a **supported** base image version (`python:3.12-slim`, not `python:3.8`/`latest`).
2. Copy dependency files first, install, then copy code (faster cached rebuilds).
3. `--no-cache-dir` / `--omit=dev` keeps images small.
4. Create and switch to a non-root `USER`.
5. Never put secrets in `ENV`, `ARG` or copied files. Use runtime env, Docker secrets or mounted files.
6. Scan the result: `docker scout cves <image>` or `trivy image <image>`.

## Compose checklist
- Only publish ports that humans or external clients need. Services talk to each other
  by service name on the internal network (Redis in `docker-compose/` has no published port).
- Bind dev-only ports to localhost: `"127.0.0.1:9229:9229"`.
- Keep secrets in git-ignored files (`.env`, `db/password.txt`). Commit a `.example` template.
