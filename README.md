# SciLifeLab Serve

SciLifeLab Serve ([https://serve.scilifelab.se](https://serve.scilifelab.se)) is a platform offering machine learning model serving, app hosting (Shiny, Streamlit, Dash, etc.), web-based integrated development environments, and other tools to life science researchers affiliated with a Swedish research institute. It is developed and operated by the [SciLifeLab Data Centre](https://github.com/ScilifelabDataCentre), part of [SciLifeLab](https://scilifelab.se/). See [this page for information about funders and mandate](https://serve.scilifelab.se/about/).

This repository contains Helm charts for SciLifeLab Serve.

## Reporting bugs and requesting features

If you are using SciLifeLab Serve and notice a bug or if there is a feature you would like to be added feel free to [create an issue](https://github.com/ScilifelabDataCentre/serve/issues/new/choose) with a bug report or feature request.

## How to deploy

### Prerequisites

- A Kubernetes cluster version **1.28.6**
- Helm 3
- A storage class for dynamic provisioning of persistent volumes

If you are going to run this on a remote cluster, then you probably don't need to think about this
as these things will be provided by your cloud provider.

But in case of a local deployment, navigate to the next section.

#### Setup for local deployment

If you are going to run this locally, you need to have a Kubernetes cluster running on your machine. 
You can use [Rancher Desktop](https://rancherdesktop.io/) for this purpose.

Follow their instruction to install Rancher Desktop, and then start it.

Recommended settings for Rancher Desktop:
- `Preferences > Kubernetes` select kubernetes version `1.28.6`.
- `Preferences > Container Engine` select `containerd` as the container engine.
- `Preferences > Virtual Machine > Emulation` select `QEMU`
  - If you are running on an M3 Mac select `VZ`
- `Preferences > Virtual Machine > Hardware` select `4 CPUs` and `16 GB` of memory.

##### Serve image

By default, the image is pulled from the public registry. This image is the one we are using in production.
So you don't need to build the image yourself if you want to just try it out locally.

But if you want to develop, you need to build the image yourself.

**Building image for Rancher Desktop**

Rancher Desktop brings a number of tools when you install it. 
One of them is `nerdctl` which is a drop-in replacement for `docker` and `docker-compose`.

Rancher Desktop also brings a local registry that you can use to push images to. 
And this registry can be accessed from your Kubernetes cluster and used as if you were using docker.

See [Serve](https://github.com/ScilifelabDataCentre/serve/) repository for up-to-date instructions on 
how to build the image for local development.

But this setup expects that you have an image tagged `mystudio` built using `nerdctl` and pushed to the `k8s.io` namespace.

### Deploying

> Using the following you'll make sure that your Rancher Desktop installation is working as expected using the default settings.
> These instructions are almost the same as the ones you would use for a remote cluster except for the storage class.
> If it doesn't work you should debug your installation and contact team members for help.

**Outcomes of this section**
- You'll prepare your environment for the proper local deployment of Serve;
- Running instance of Serve on your local machine available on [http://studio.127.0.0.1.nip.io/](http://studio.127.0.0.1.nip.io/).



First, clone this repository

```bash
$ git clone https://github.com/ScilifelabDataCentre/serve-charts.git
```

Then navigate to the `serve-charts/serve` folder

```bash
$ cd serve-charts/serve
```

Now you need to create an override file for the `values.yaml` file.

Create a file called `values-local.yaml` from the example template `values-local.example.yaml`.

This is necessary because the default values are set for a production environment. Specifically, the storage class 
has to change because the default storage class is not available in a Rancher Desktop environment.

```bash
$ helm dependency update
# The following command will install the chart with the values from values.yaml and values-local.yaml
# values-local.yaml will override the values from values.yaml
$ helm install serve . -f values.yaml -f values-local.yaml
```

As a result you should have a running instance of Serve on your local machine available on [http://studio.127.0.0.1.nip.io/](http://studio.127.0.0.1.nip.io/).

#### Swapping default docker image with the one built locally

<details>
  <summary>TJ;DR Just commands</summary>

  ```bash
  $ git clone https://github.com/ScilifelabDataCentre/serve-charts.git
  $ cd serve-charts/serve
  $ cat <<EOF > values-local.yaml
environment: "vscode"
source_code_path: "/path/to/your/local/serve"

storageClass: &storage_class local-path
access_mode: &access_mode ReadWriteOnce
accessmode: *access_mode
accessModes:
  - ReadWriteOnce

bitwarden:
  enabled: false

namespace: default

studio:
  domain: studio.127.0.0.1.nip.io
  session_cookie_domain: .127.0.0.1.nip.io
  superuserPassword: "yourpassword"
  superuserEmail: "your.email@example.com"
  djangoAdminUrlPath: "admin"
  storageClass: *storage_class
  debug: true
  inactive_users: false
  storage:
    storageClass: *storage_class
  media:
    storage:
      storageClass: *storage_class
      accessModes: *access_mode
  csrf_trusted_origins: "https://studio.127.0.0.1.nip.io:8080"
  superUser: admin
  static:
    image:
      repository: mystudio
      tag: latest
      imagePullPolicy: Never
  image:
    repository: mystudio
    tag: latest
    imagePullPolicy: Never
  resources:
    limits:
      cpu: "1000m"
      memory: "4Gi"
    requests:
      cpu: "400m"
    media:
      mountStudio: false
  emailService:
    enabled: false

securityContext:
  enabled: false

readinessProbe:
  enabled: false

livenessProbe:
  enabled: false

rabbitmq:
  auth:
    erlangCookie:
    existingPasswordSecret: ""
    existingPasswordSecretKey: ""
    erlangCookie:
  resources:
    limits:
      cpu:
      ephemeral-storage: 50Mi
      memory:
    requests:
      cpu:
      ephemeral-storage: 50Mi
      memory:

redis:
  enabled: true
  auth:
    existingSecret: ""
    existingSecretPasswordKey: ""

celeryFlower:
  enabled: true

bitwarden:
  enabled: false

networkPolicy:
  enable: false
  kubernetes:
    cidr:
    port: 6443 
  internal_cidr:
    - 10.0.0.0/8
    - 192.168.0.0/16
    - 172.0.0.0/20
  ingress_controller_namespace: kube-system

ingress:
  djangoAdminAccessRestriction:
    enabled: false
  hosts:
    - host: studio.127.0.0.1.nip.io
  tls: []

reloader:
  enabled: true
  namespace: default

postgresql:
  storageClass: *storage_class
  auth:
    username: postgres
    database: postgres
    password:
    existingSecret: ""
    secretKeys:
      adminPasswordKey: ""
      userPasswordKey: ""
  primary:
    persistence:
      storageClass: *storage_class
      accessModes:
        - *access_mode
  EOF
  $ helm upgrade serve . -f values.yaml -f values-local.yaml
  ```
</details>

**Outcomes of this section:**
- Instead of a Django server, you'll have an ssh server running for the [PyCharm setup](https://github.com/ScilifelabDataCentre/serve/?tab=readme-ov-file#deploy-serve-for-local-development-with-rancher-desktop)
- You'll have a host machine's folder with the [Serve](https://github.com/ScilifelabDataCentre/serve/) code mounted to the container;

Now that everything is running, you can swap the default image with the one you built locally.

> See the [Serve image section](https://github.com/ScilifelabDataCentre/serve/?tab=readme-ov-file#deploy-serve-for-local-development-with-rancher-desktop) for instructions on how to build the image.

Go back to the `values-local.yaml` file update it with the following content:

<details>
  <summary>Full content of the values-local.yaml file</summary>
  
```yaml
environment: "vscode"
source_code_path: "/path/to/your/local/serve"

storageClass: &storage_class local-path
access_mode: &access_mode ReadWriteOnce
accessmode: *access_mode
accessModes:
  - ReadWriteOnce

bitwarden:
  enabled: false

namespace: default

studio:
  domain: studio.127.0.0.1.nip.io
  session_cookie_domain: .127.0.0.1.nip.io
  superuserPassword: "yourpassword"
  superuserEmail: "your.email@example.com"
  djangoAdminUrlPath: "admin"
  storageClass: *storage_class
  debug: true
  inactive_users: false
  storage:
    storageClass: *storage_class
  media:
    storage:
      storageClass: *storage_class
      accessModes: *access_mode
  csrf_trusted_origins: "https://studio.127.0.0.1.nip.io:8080"
  superUser: admin
  static:
    image:
      repository: mystudio
      tag: latest
      imagePullPolicy: Never
  image:
    repository: mystudio
    tag: latest
    imagePullPolicy: Never
  resources:
    limits:
      cpu: "1000m"
      memory: "4Gi"
    requests:
      cpu: "400m"
    media:
      mountStudio: false
  emailService:
    enabled: false

securityContext:
  enabled: false

readinessProbe:
  enabled: false

livenessProbe:
  enabled: false

rabbitmq:
  auth:
    erlangCookie:
    existingPasswordSecret: ""
    existingPasswordSecretKey: ""
    erlangCookie:
  resources:
    limits:
      cpu:
      ephemeral-storage: 50Mi
      memory:
    requests:
      cpu:
      ephemeral-storage: 50Mi
      memory:

redis:
  enabled: true
  auth:
    existingSecret: ""
    existingSecretPasswordKey: ""

celeryFlower:
  enabled: true

bitwarden:
  enabled: false

networkPolicy:
  enable: false
  kubernetes:
    cidr:
    port: 6443 
  internal_cidr:
    - 10.0.0.0/8
    - 192.168.0.0/16
    - 172.0.0.0/20
  ingress_controller_namespace: kube-system

ingress:
  djangoAdminAccessRestriction:
    enabled: false
  hosts:
    - host: studio.127.0.0.1.nip.io
  tls: []

reloader:
  enabled: true
  namespace: default

postgresql:
  storageClass: *storage_class
  auth:
    username: postgres
    database: postgres
    password:
    existingSecret: ""
    secretKeys:
      adminPasswordKey: ""
      userPasswordKey: ""
  primary:
    persistence:
      storageClass: *storage_class
      accessModes:
        - *access_mode
  ```

</details>

After doing this run the following command to upgrade the deployment:

```bash
helm upgrade serve . -f values.yaml -f values-local.yaml
```

Now you can proceed to [set up PyCharm](https://github.com/ScilifelabDataCentre/serve?tab=readme-ov-file#pycharm-setup)

If you don't want to set up PyCharm, you can just run Django from the container.

```bash
$ kubectl get po
# Get the name of the studio pod
$ kubectl exec -it <studio-pod-name> -- /bin/bash
# Now you are inside the container 
$ sh scripts/run_web.sh
```

Please note, that the folder you are in, `/app`, is the folder where the code is mounted.

It means that you can make changes to the code on your host machine and see the changes in the container.

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
    repository: k3d-registry:35187/serve:develop #This image can be built from Dockerfile (https://github.com/scaleoutsystems/serve)
    pullPolicy: Always # used to ensure that each time we redeploy always pull the latest image
  static:
    image: k3d-registry:35187/serve-nginx:develop #This image can be built from Dockerfile.nginx (https://github.com/scaleoutsystems/serve)
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