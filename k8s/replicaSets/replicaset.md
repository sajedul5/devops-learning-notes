Let's now use the ReplicaSet template instead of the Pod template.

## Create the ReplicaSet

    kubectl apply -f replicaset.yaml

## Get the pods list

    kubectl get pods -o wide

## Get the ReplicaSet name

    kubectl get rs

## Describe the ReplicaSet

    kubectl describe rs rs-example

## Cleanup

    kubectl delete -f replicaset.yaml
    kubectl delete rs rs-example