kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

kubectl apply -f load-test-pod.yaml

kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
kubectl delete -f hpa.yaml