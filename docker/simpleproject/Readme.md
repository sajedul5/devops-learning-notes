# Multi-container app with Docker Compose (React + Node.js + MariaDB)

> ⚠️ **Legacy sample code.** This folder also contains copies of Docker's older
> "example-voting-app" (`vote/`, `result/`, `worker/`) that use **end-of-life base
> images** (Python 2.7, Node 8/10, .NET Core 2.x, `microsoft/dotnet`). They are kept
> for reading only — they have known vulnerabilities, may not build, and must
> never be deployed. The `compose.yaml` stack below (frontend/backend/db) is the
> part to run.

## 1. Create the database password (Docker secret)

The DB password is passed as a **Docker secret file**, not an environment variable,
so it does not show up in `docker inspect` or process listings.

    openssl rand -base64 24 > db/password.txt     # git-ignored, never commit it

(`db/password.txt.example` shows the expected format: one line, the password.)

## 2. Build the app

    docker compose build

## 3. Run the app

    docker compose up -d

This will take a while. When the app is running, open http://localhost:3000

## List the containers

    docker compose ps

## Look at the backend container logs

    docker compose logs -f backend

Refresh the frontend page a few times; the logs should display each hit.

## Stop the app

    docker compose down          # add -v to also delete the database volume

## Things to notice (security)
- The `db` service is only on the `private` network, so the frontend cannot reach it
  and it publishes no ports to the host.
- Ports `9229/9230` (Node debugger) are published for development only. A debugger
  port gives full code execution — never publish it on a server.
