# ELK Stack (Elasticsearch + Logstash + Kibana)

Single-node logging stack for learning. Filebeat agents ship logs to Logstash
(port 5044), Logstash writes them to Elasticsearch, and you search them in Kibana.

```
Filebeat ──5044──▶ Logstash ──▶ Elasticsearch ◀── Kibana (http://localhost:5601)
```

## Run it

```bash
cd elk
cp .env.example .env
sed -i "s|^ELASTIC_PASSWORD=.*|ELASTIC_PASSWORD=$(openssl rand -base64 18)|" .env   # strong random password
docker compose up -d
docker compose ps          # wait until elasticsearch is "healthy"
```

Open http://localhost:5601 and log in as `elastic` with the password from `.env`.

On a remote server, open an SSH tunnel first:
`ssh -L 5601:localhost:5601 user@server`.

Check Elasticsearch directly:

```bash
set -a; . ./.env; set +a
curl -u "elastic:$ELASTIC_PASSWORD" http://localhost:9200/_cluster/health?pretty
```

Point Filebeat at `<server-ip>:5044`. Indices are named `filebeat-test-YYYY.MM.dd`.
In Kibana: *Stack Management → Index Patterns → `filebeat-test-*`*.

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | the three services, health check, volumes |
| `.env.example` | template for `.env` (password and version). `.env` is git-ignored |
| `logstash.conf` | pipeline: Beats input → Elasticsearch output (password read from env) |
| `elasticsearch.yml`, `kibana.yml`, `logstash.yml` | service configs |

## Security notes
- **Security is enabled** (`xpack.security.enabled=true`). An open Elasticsearch on the
  internet gets wiped or ransomed within hours. This is one of the most common real-world breaches.
- Ports 9200, 5601 and 9600 bind to `127.0.0.1` only. Port 5044 is open for remote
  agents: firewall it to their IPs (`ufw allow from <agent-ip> to any port 5044`).
- Version `7.17.x` is used because 7.9 (the original version here) is affected by
  Log4Shell (CVE-2021-44228). For new projects use Elastic 8.x, which turns on TLS by default.
- Kibana uses the `elastic` superuser here for simplicity. In real setups create the
  `kibana_system` password and a least-privilege `logstash_writer` role/user.

## Stop / reset

```bash
docker compose down        # stop
docker compose down -v     # stop AND delete all indexed data
```
