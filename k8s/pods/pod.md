# L21-04

Let’s first create a node running Nginx by using the imperative way.

## Create the pod

    kubectl run mynginx --image=nginx

## Get a list of running pods

    kubectl get pods

## Get more info

    kubectl get pods -o wide
    kubectl describe pod mynginx

## Delete the pod

    kubectl delete pod mynginx

## Create a pod running BusyBox

Let’s now create a node running BusyBox, this time attaching bash to our terminal.

    kubectl run mybox --image=busybox -it -- /bin/sh

## List the folders and use command

    ls
    echo -n 'A Secret' | base64
    exit

## Cleanup

    kubectl delete pod mybox

## Create a pod using the declarative way

Let’s now create a node using a YAML file.

    kubectl create -f pod.yaml

## Get some info

    kubectl get pods -o wide
    kubectl describe pod myapp-pod

## Attach our terminal

    kubectl exec -it myapp-pod -- bash

Print the DBCON environment variable that was set in the YAML file.

    echo $DBCON

## Detach from the instance

    exit

## Cleanup

    kubectl delete -f pod.yaml


Let's use an Init container.

## Create the deployment

    kubectl apply -f init-container.yaml

Wait for the main pod to come up

    kubectl get pods

## Connect to the Nginx container

    kubectl exec -it init-demo -- /bin/bash

## Hit the default webpage

It should be the one downloaded by the Init container from https://www.google.com

    curl localhost
    exit

## Cleanup

    kubectl delete -f init-container.yaml