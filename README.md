# SciLifeLab Serve

[SciLifeLab Serve](https://serve.scilifelab.se) is a platform for life science researchers affiliated with a Swedish research institute. It supports hosting of web apps (Shiny, Streamlit, Dash, etc.), serving machine learning models, web-based development environments, and more. It is developed and operated by the [SciLifeLab Data Centre](https://github.com/ScilifelabDataCentre), part of [SciLifeLab](https://scilifelab.se/). See [this page](https://serve.scilifelab.se/about/) for information about funders and mandate.

This repository contains Helm charts for SciLifeLab Serve.

## Reporting bugs and requesting features

If you notice a bug or would like to request a new feature, please [create an issue](https://github.com/ScilifelabDataCentre/serve/issues/new/choose).

## How to deploy

### Prerequisites

- A Kubernetes cluster version **1.33.1**
- Helm 3
- A storage class for dynamic provisioning of persistent volumes
- An ingress controller: either the NGINX Ingress Controller (legacy) or NGINX Gateway Fabric (Gateway API)

#### Setup for local deployment

For local deployment, you need a Kubernetes cluster running on your machine. We recommend [Rancher Desktop](https://rancherdesktop.io/).

Once installed, start Rancher Desktop with the following recommended settings:

- `Preferences > Kubernetes`: select Kubernetes version `1.33.1`
- `Preferences > Container Engine`: select `containerd`
- `Preferences > Virtual Machine > Emulation`: select `QEMU` (or `VZ` on Apple M3)
- `Preferences > Virtual Machine > Hardware`: `4 CPUs` and `16 GB` memory

#### Serve image

By default, the image is pulled from the public registry, which is sufficient for trying out Serve locally. If you want to actively develop, you will need to build the image yourself.

#### Building image for Rancher Desktop

Rancher Desktop includes `nerdctl`, a drop-in replacement for `docker` and `docker-compose`, as well as a local registry accessible from your Kubernetes cluster.

See the [Serve](https://github.com/ScilifelabDataCentre/serve/) repository for up-to-date instructions on building the image for local development. This setup (local) expects an image tagged `mystudio`, built with `nerdctl` and pushed to the `k8s.io` namespace.

#### Deploying

First, clone this repository

```Bash
git clone https://github.com/ScilifelabDataCentre/serve-charts.git
```

Then navigate to the `serve-charts/serve` folder

```Bash
cd serve-charts/serve
```

Create a `values-local.yaml` override file from the provided template `values-local.example.yaml`. This is required because the default storage class in `values.yaml` is not available in Rancher Desktop.

```Bash
cp values-local.example.yaml values-local.yaml
```

You can make further edits to `values-local.yaml` should you wish to do so.

```Bash
helm dependency update
# values-local.yaml overrides values from values.yaml
helm install serve . -f values.yaml -f values-local.yaml
```

Serve should now be running locally at [http://studio.127.0.0.1.nip.io/](http://studio.127.0.0.1.nip.io/).

#### Using a locally built image

To use a locally built image, update the image and tag fields in your `values-local.yaml` to point to the image you built (tagged `mystudio` in the `k8s.io` namespace), then upgrade the deployment:

> See the [Serve image section](https://github.com/ScilifelabDataCentre/serve/?tab=readme-ov-file#deploy-serve-for-local-development-with-rancher-desktop) for instructions on how to build a local image.

#### Using PyCharm

You can now [set up PyCharm](https://github.com/ScilifelabDataCentre/serve?tab=readme-ov-file#pycharm-setup), or run Django directly from the container:

```Bash
kubectl get po
# Get the name of the studio pod
kubectl exec -it <studio-pod-name> -- /bin/bash
```

The `/app` directory inside the container is where the code is mounted, so any changes made on your host machine will be reflected immediately in the container.

## Deploy an SSL certificate

For production, you need a wildcard SSL certificate for your domain. For example, if your domain is `your-domain.com`, you will need a certificate covering `*.your-domain.com` and `*.studio.your-domain.com`. Create the `prod-ingress` TLS secret using:

```Bash
kubectl create secret tls prod-ingress --cert fullchain.pem --key privkey.pem
```

The secret must be created in the same namespace as the Serve deployment.

## Enabling network policies

When `networkPolicy.enable = true`, you must set the correct Kubernetes API server IP and port in `networkPolicy.kubernetes.cidr` and `networkPolicy.kubernetes.port`. This allows certain services to reach the API server via a Service Account. To get your cluster's Kubernetes endpoint:

```Bash
kubectl get endpoints kubernetes
```

To allow within-cluster DNS resolution, label the `kube-system` namespace:

```Bash
kubectl label namespace kube-system name=kube-system
```

For ingress resources, set `networkPolicy.ingress_controller_namespace` to the namespace of your ingress controller — typically `ingress-nginx` for the NGINX Ingress Controller, or `gateway` when using NGINX Gateway Fabric.
