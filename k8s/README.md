# Kubernetes Labs

One folder per concept. Each has YAML manifests plus a `.md` file with the
commands to run. Follow the order below. Any cluster works: k3s
([`../setup-docker-k3s.sh`](../setup-docker-k3s.sh)), kind, minikube or Docker Desktop.

| # | Lab | Concepts |
|---|---|---|
| 1 | [k8s-config.md](k8s-config.md), [k8s-namespace.md](k8s-namespace.md) | kubeconfig contexts, namespaces |
| 2 | [pods/](pods/) | pods, multi-container pods, init containers |
| 3 | [selectors/](selectors/) | labels and selectors |
| 4 | [replicaSets/](replicaSets/) | keeping N replicas alive |
| 5 | [deployments/](deployments/) | declarative updates |
| 6 | [rolling-update/](rolling-update/) | rollout, history, rollback |
| 7 | [livenessProbe/](livenessProbe/) | health checks |
| 8 | [clusterIP/](clusterIP/), [nodePort/](nodePort/), [load-balancer/](load-balancer/) | Service types |
| 9 | [ingress/](ingress/) | HTTP routing with ingress-nginx |
| 10 | [configmaps/](configmaps/), [secrets/](secrets/) | configuration and credentials (**read the warnings in secrets/**) |
| 11 | [volume/](volume/), [statefulset/](statefulset/) | PV/PVC, stable identity + storage |
| 12 | [daemonset/](daemonset/), [job/](job/) | one pod per node, run-to-completion |
| 13 | [resource-management/](resource-management/) | requests/limits, LimitRange, ResourceQuota |
| 14 | [scale-pods/](scale-pods/), [autoscaling/](autoscaling/) | metrics-server, HPA, load testing |
| 15 | [blue-green-deployment/](blue-green-deployment/) | zero-downtime releases (see also [`../rnd/`](../rnd/)) |
| 16 | [k3s-install/](k3s-install/), [multi-k8s-cluster.md](multi-k8s-cluster.md) | building clusters: k3s and HA kubeadm |
| — | [docs.md](docs.md) | reading list of Kubernetes failure stories |

## Lab-only shortcuts (don't copy these into production)

| Shortcut | Where | Production alternative |
|---|---|---|
| Secret values committed in YAML | `secrets/secrets.yaml` | `kubectl create secret`, Sealed Secrets, SOPS, External Secrets |
| `hostPath` volumes | `volume/`, `statefulset/` | a StorageClass / CSI driver |
| `--kubelet-insecure-tls` | `scale-pods/components.yaml` | kubelet serving certs signed by the cluster CA |
| Pods without `securityContext` | most labs (kept short on purpose) | the hardened template in [`../SECURITY.md`](../SECURITY.md#5-kubernetes) and [`../rnd/k8s/`](../rnd/k8s/) |

Clean up after each lab with `kubectl delete -f <file>.yaml` (or `-f .` for the whole folder).
