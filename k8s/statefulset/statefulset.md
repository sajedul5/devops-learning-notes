Let's now create a StafulSet.

## Create the Deployment

    kubectl apply -f statefulset.yaml

## Get the pods list

    kubectl get pods -o wide

## Get a list of the PersistentVolumes Claims

    kubectl get pvc

## Create a file in my-statefulset-2

Open a session in my-statefulset-2 and create a file in the folder mapped to the volume.

    kubectl exec my-statefulset-2 -it -- /bin/sh
    cd var/www
    echo Hello > hello.txt

## Modify the default Web page

    cd /usr/share/nginx/html
    cat > index.html
    Hello
    Ctrl-D
    exit



## Delete pod 2

Delete a pod and watch as it is recreated with the same name.

    kubectl delete pod my-statefulset-2

## Is the file still there?

Open a session in my-statefulset-2 and see if the file is still present.

    kubectl exec my-statefulset-2 -it -- /bin/sh
    ls var/www
    exit

## Cleanup

    kubectl delete -f statefulset.yaml
    kubectl delete pvc my-storage-my-statefulset-0
    kubectl delete pvc my-storage-my-statefulset-1
    kubectl delete pvc my-storage-my-statefulset-2

## PVC
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl get pv
kubectl get pvc
kubectl get statefulset
kubectl get pods