STACKn
======
[<img src="https://github.com/scaleoutsystems/charts/actions/workflows/release.yaml/badge.svg">](https://github.com/scaleoutsystems/charts/actions/workflows/release.yaml)
[<img src="https://github.com/scaleoutsystems/charts/actions/workflows/code-checks.yaml/badge.svg">](https://github.com/scaleoutsystems/charts/actions/workflows/code-checks.yaml)

## Description

A Helm chart for deploying STACKn by Scaleout

Current chart version is 0.3.0

## Chart Requirements

| Repository | Name | Version | Optional |
|------------|------|---------|----------|
| https://charts.bitnami.com/bitnami | postgresql | 12.2.7 | No
| https://charts.bitnami.com/bitnami | redis | 17.7.4 | No
| https://charts.bitnami.com/bitnami | rabbitmq | 11.9.1 | No
| https://charts.bitnami.com/bitnami | common | 2.0.4 | No
| https://stakater.github.io/stakater-charts | reloader | v1.0.15 | Yes

## Notes
When using PVC's together with postgres, rabbitmq and and redis, credentials will to not sync if secrets are updated (for example if password values are left blank). If this happens, the solution 
is to redeploy and delete previous created PVCs. To avoid the same problem again, either set password values or use existing secrets. The subcharts for postgres, rabbitmq and redis all come with a value
to set existing secret. Existing secrets is the recommended approch if are going to version control your values (GitOps) to avoid raw passwords in your version history.

You can read more about the issue here: https://github.com/bitnami/charts/issues/2061
Obs that stakater/reloader does not solve the issue.
## Configuration

By default STACKn has been configured with a dns wildcard domain for localhost. To change this replace all occurences of studio.127.0.0.1.nip.io in values.yaml.

By default no StorageClassName is set and needs to provided in the values.yaml or by using `--set` argument.

### Quick deployment

```bash
# Deploy STACKn from this repository
helm install --set global.postgresql.storageClass=<your-storage-class> studio .
```

All resources will by default be created in the Namescape "default".
STACKn studio will be avaliable at https://studio.127.0.0.1.nip.io
Obs that you might have to make changes to your particular ingress controller (nginx is supported in this chart) to connect to the URL.
If the ingress does not work for any reason, you can try to port-forward the studio service port to your localhost. 

## Deploy an SSL certificate

For production you need a domain name with a wildcard SSL certificate. If your domain is your-domain.com, you will need a certificate for *.your-domain.com and *.studio.your-domain.com. Assuming that your certificate is fullchain.pem and your private key privkey.pem, you can create a secret `prod-ingress` containing the certificate with the command:
```
kubectl create secret tls prod-ingress --cert fullchain.pem --key privkey.pem
```

This secret should be in the same namespace as studio deployment.

## Enabling network policies
If networkPolicy.enable = true, you have to make sure the correct kubernetes endpoint IP is provided in networkPolicy.kubernetes.cidr, and the correct port networkPolicy.kubernetes.port. This is to enable access of some services to the kubernetes API server through a created Service Account. To get your cluster's kubernetes endpoint run:
```
kubectl get endpoints kubernetes
```
To allow for within-cluster DNS, the kube-system namespace need the label:
```
kubectl label namespace kube-system name=kube-system
```

Further, for ingress resources you need to set  networkPolicy.ingress_controller_namespace. If value can vary depending on your cluster configuration, but for NGINX ingress controller it's usually "ingress-nginx".

## Example deployment
```
global:
  studio:
    superuserPassword: adminstudio # Django superuser password, username is admin
  postgresql:
      auth:
        username: studio
        password: studiopostgrespass
        postgresPassword: postgres
        database: studio
      storageClass: local-path 

namespace: default
networkPolicy:
  enable: true
  kubernetes:
    cidr: 127.0.0.1/32 # To get kubernetes api server endpoints run: $ kubectl get endpoints kubernetes
    port: 6443
  internal_cidr: # in-cluster IpBlock cidr, used in allow-internet-[egress|ingress] policy, e.g:
    - 10.0.0.0/8
    - 192.168.0.0/16
    - 172.0.0.0/20

studio:
  debug: false
  inactive_users: false #Users that sign-up can be inactive by default if desired
  csrf_trusted_origins: "https://studio.127.0.0.1.nip.io:8082" #extra trusted origin for django server, for example if you port-forward to port 8082
  image: # using a local image registry with hostname k3d-registry
    repository: k3d-registry:35187/stackn:develop #This image can be built from Dockerfile (https://github.com/scaleoutsystems/stackn)
    pullPolicy: Always # used to ensure that each time we redeploy always pull the latest image
  static:
    image: k3d-registry:35187/stackn-nginx:develop #This image can be built from Dockerfile.nginx (https://github.com/scaleoutsystems/stackn)
  media:
    storage:
      accessModes: ReadWriteOnce

accessmode: ReadWriteOnce

# Postgres deploy with a single-pod database:
postgresql:
  primary:
    persistence:
      size: "2Gi"
      accessModes:
        - ReadWriteOnce
      storageClass: local-path

rabbit:
  password: rabbitmqpass

redis:
  master:
    persistence:
      enabled: false
  replica:
    persistence:
      enabled: false

celeryFlower:
  enabled: false

reloader:
  enabled: true
```


## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Fredrik Wrede | fredrik@scaleoutsystems.com |  |
