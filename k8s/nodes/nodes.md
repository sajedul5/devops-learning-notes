# Choosing which node a pod runs on

## List the nodes and their labels

    kubectl get nodes --show-labels

## Deploy. The pod stays Pending: no node has the label yet

    kubectl apply -f task-devops-deployment.yaml
    kubectl get pods -o wide
    kubectl describe pod -l app=nginx | grep -A3 Events     # "didn't match Pod's node affinity/selector"

## Label a node, and the pod gets scheduled there

    kubectl label node <node-name> lab/role=web
    kubectl get pods -o wide        # NODE column shows <node-name>

## Remove the label (running pods stay; new pods won't schedule)

    kubectl label node <node-name> lab/role-

## Cleanup

    kubectl delete -f task-devops-deployment.yaml

> `nodeSelector` is the simple form. For "prefer" rules, spreading and
> anti-affinity, see `affinity` and `topologySpreadConstraints` in the Kubernetes docs.
