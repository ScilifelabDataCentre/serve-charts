# SciLifeLab Serve

SciLifeLab Serve ([https://serve.scilifelab.se](https://serve.scilifelab.se)) is a platform offering machine learning model serving, app hosting (Shiny, Streamlit, Dash, etc.), web-based integrated development environments, and other tools to life science researchers affiliated with a Swedish research institute. It is developed and operated by the [SciLifeLab Data Centre](https://github.com/ScilifelabDataCentre), part of [SciLifeLab](https://scilifelab.se/). See [this page for information about funders and mandate](https://serve.scilifelab.se/about/).

This repository contains Helm charts for SciLifeLab Serve. It is  based on the open-source platform [Stackn](https://github.com/scaleoutsystems/stackn).

## Reporting bugs and requesting features

If you are using SciLifeLab Serve and notice a bug or if there is a feature you would like to be added feel free to [create an issue](https://github.com/ScilifelabDataCentre/stackn/issues/new/choose) with a bug report or feature request.

## How to deploy
First, clone this repository
```
git clone https://github.com/ScilifelabDataCentre/serve-charts.git
```

Then navigate to the `serve-charts/serve` folder, and run

```
helm dependency update
helm install serve .
```

Depending on your storageclass, you might have to set this aswell. 
For instance, if you use `microk8s`, them you run

```
helm install --set global.postgresql.storageClass=microk8s-hostpath serve .
```

All resources will by default be created in the default namespace.
Serve will be avaliable at https://studio.127.0.0.1.nip.io
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