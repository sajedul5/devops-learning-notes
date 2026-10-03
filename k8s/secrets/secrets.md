# Kubernetes Secrets

> ⚠️ **base64 is not encryption.** A Secret manifest in git is a leaked secret.
> `secrets.yaml` here contains dummy values for practice only. For real projects,
> create Secrets from the command line or use Sealed Secrets / SOPS / External
> Secrets Operator. See [SECURITY.md](../../SECURITY.md).

## Encode / decode values

    echo -n [string] | base64        # -n: don't encode the trailing newline
    echo [encodedString] | base64 -d

## Safer: create a Secret without writing it to a file

    kubectl create secret generic secrets \
      --from-literal=username=TheUserName \
      --from-literal=password="$(openssl rand -base64 18)"

## Prefer mounting secrets as files over env vars
Env vars leak easily (crash dumps, `env` in debug sessions, child processes).
A `volumeMounts` + `secret` volume is usually safer.

    echo [string] | base64
    echo [encodedString] | base64 -d

## Create the Secrets

    kubectl apply -f secrets.yaml

## Look at the secrets

    kubectl get secret
    kubectl describe secret secrets
    kubectl get secret secrets -o YAML

## Deploy the pod

    kubectl apply -f pod.yaml

## Connect to the Busybox

    kubectl exec -it mybox  -- /bin/sh

## Display the USERNAME and PASSWORD env variables

    echo $USERNAME
    echo $PASSWORD
    exit

## Cleanup

    kubectl delete -f secrets.yaml
    kubectl delete -f pod.yaml --force --grace-period=0