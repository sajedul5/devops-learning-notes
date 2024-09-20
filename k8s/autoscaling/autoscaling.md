kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

kubectl apply -f load-test-pod.yaml

