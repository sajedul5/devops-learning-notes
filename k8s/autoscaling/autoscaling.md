# Horizontal Pod Autoscaler (HPA)

The HPA adds pods when average CPU goes above the target in `hpa.yaml`, and removes
them when load drops. It needs **metrics-server** (built into k3s; check with
`kubectl top nodes`).

## Deploy the app, service and autoscaler

    kubectl apply -f deployment.yaml
    kubectl apply -f service.yaml
    kubectl apply -f hpa.yaml
    kubectl get hpa                 # TARGETS shows "<unknown>" for ~30s, then a %

## Generate load and watch it scale (open two terminals)

    kubectl apply -f load-test-pod.yaml
    kubectl get hpa nginx-hpa -w    # REPLICAS climbs within 1–2 minutes
    kubectl top pods

## Stop the load. It scales back down after ~5 minutes (stabilization window)

    kubectl delete pod load-test
    kubectl get hpa nginx-hpa -w

## Cleanup

    kubectl delete -f .

`loadtesh.sh` is an alternative load generator you can run from your own machine
against a LoadBalancer/NodePort URL (edit `URL=` at the top first).
