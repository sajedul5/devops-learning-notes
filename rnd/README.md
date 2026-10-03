# Release strategies: Blue-Green & Canary on k3s (Traefik)

Two small Node.js services and the Kubernetes manifests to release them safely.

```
rnd/
├── app/
│   ├── api/                  # Express API on :4000  (/api, /health, /ready)
│   ├── frontend/             # Express UI on :3000 — calls the API (canary variant)
│   └── frontend-blue-green/  # same UI, styled as blue/green versions
└── k8s/
    ├── app/                  # baseline: api + frontend Deployments, Services, Ingress
    ├── blue-green-deploy/    # two Deployments + switchable Service
    └── canary-deploy/        # extra canary Deployment sharing the stable Service
```

## Build images

```bash
docker build -t <you>/devops:api-v1           rnd/app/api
docker build -t <you>/devops:frontend-v1      rnd/app/frontend
docker build -t <you>/devops:frontend-blue    rnd/app/frontend-blue-green   # edit text/colour per version
docker push <you>/devops:api-v1   # ...and the others
```

The images run as the unprivileged `node` user, and the manifests enforce it with
`runAsNonRoot`, a read-only root filesystem, dropped capabilities and no
service-account token. Copy that template for your own apps.

## Baseline

```bash
kubectl create namespace app
kubectl apply -f rnd/k8s/app/api/ -f rnd/k8s/app/frontend/
echo "<node-ip> app.local api.local" | sudo tee -a /etc/hosts
curl http://app.local
```

> Tip: inside the cluster, pods may not resolve `api.local`. Set
> `API_URL=http://api.app.svc.cluster.local` to use cluster DNS instead.

## Blue-Green
Both versions run at full size; the `frontend` Service selects `version: blue` or
`version: green`. Switching is instant, and so is rolling back.

```bash
kubectl apply -f rnd/k8s/blue-green-deploy/deploy-blue.yaml -f rnd/k8s/blue-green-deploy/deploy-green.yaml
kubectl apply -f rnd/k8s/blue-green-deploy/service-blue.yaml    # live = blue
kubectl apply -f rnd/k8s/blue-green-deploy/service-green.yaml   # switch to green
kubectl apply -f rnd/k8s/blue-green-deploy/service-blue.yaml    # rollback
```

## Canary
The canary pods carry `app: frontend`, so the stable `frontend` Service sends them
traffic **in proportion to pod count** (3 stable + 1 canary ≈ 25%).

```bash
kubectl apply -f rnd/k8s/canary-deploy/
kubectl scale deploy/frontend --replicas=3 -n app
for i in $(seq 20); do curl -s http://app.local | grep -o '<h1>.*</h1>'; done | sort | uniq -c
kubectl delete deploy/frontend-canary -n app      # abort the canary
```

For exact percentages independent of replica counts, use a Traefik `TraefikService`
with weights, or ingress-nginx's `canary-weight` annotation (see the comments in
`canary-deploy/ingress.yaml`).
