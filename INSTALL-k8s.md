# Installation on Kubernetes
Helm chart to deploy the Orchestrator solution suite on Kubernetes, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing and Knative Serving.
The main focus of this chart is for development and quality testing on local or CI environments and it is not suited for production usage.
For that reason the images used for data-index and job-service are ephemeral.

This chart will deploy the following on the target OpenShift cluster:
  - Janus IDP backstage
  - SonataFlow Operator (with Data-Index and Job Service)
  - Knative Eventing
  - Knative Serving
  - serverless workflows 

# Setting up Local Installation of Orchestrator with Helm

This document provides step-by-step instructions for developers to set up a local installation of Orchestrator

## Prerequisites

Before proceeding, ensure you have the following prerequisites installed:

- Helm v3+
- Kubernetes cluster configured (e.g., Kind, Minikube, Docker Desktop with Kubernetes enabled)

This chart has been used with kind, podman,and ingress controller extensively and is known to work.

See here for a [recommended kind installation script](#kind-installation)

See here the [troubleshooting section](#troubleshooting) 

## Installation Steps

1. **Clone the Repository**: 

    ```bash
    git clone https://github.com/parodos-dev/orchestrator-helm-chart.git
    ```

2. **Navigate to Helm Chart Directory**:

    ```bash
    cd orchestrator-helm-chart/charts/orchestrator
    ```

3. **Install dependent helm repos**:

    ```bash
    helm repo add backstage https://janus-idp.github.io/helm-backstage
    helm repo add sclorg https://sclorg.github.io/helm-charts
    helm repo add workflows https://parodos.dev/serverless-workflows-helm
    ```

4. **Update Helm Repositories**:

    ```bash
    helm repo update
    helm dep build
    ```

5. **Install the Helm Chart**:

    The Helm chart provides several configuration options that you can customize based on your requirements. Below are some of the common configuration parameters:

    - `sonataflow-operator.enabled`: Enable/Disable sonataflow operator installation
    - `sonataflow-operator.image`: The Sonataflow Operator image 
    - `serverless-knative.enabled`: Enable/Disable Knative operator installation
    - `workflows.enabled`: Enable/Disable the serverless workflows helm chart (from parodos-dev/serverless-workflows-helm)
    - `backstage.global.dynamic`: Entrypoint into the helm backstage dynamic configuration object.
    - `backstage.upstream.backstage`: Entrypoint into the helm backstage configuration object.

    You can modify these parameters either by editing the `values.yaml` file directly or by passing them as `--set` flags during the Helm installation command.

    ```bash
    helm install orchestrator . -f values.yaml -f values-k8s.yaml
    ```

    This command will install the Orchestrator chart with the release name `orchestrator`.

6. **Verify Installation**:

    ```bash
    kubectl get pods

    ```

    Ensure that the pods associated with the Orchestrator deployment are in a `Running` state.

7. **Install Serverless Workflows**

    ```bash
    helm upgrade orchestrator . -f values.yaml -f values-k8s.yaml --set workflows.enabled=true
    ```

    Ensure the new sonataflow resources are in 'Running' state.

## Accessing Orchestrator

Wait for backstage to start:

```bash
kubectl wait --for=condition=Ready=true pods -l "app.kubernetes.io/component=backstage"
```

Once the installation is successful, you can access Orchestrator using the service's NodePort or LoadBalancer, depending on your Kubernetes setup. 

To get the URL using minikube:

```bash
minikube service orchestrator --url
```

When using kind + ingress like written in [kind installation](#kind-installation) section then backstage is available at http://localhost:9090


# Kind Installation

The used configuration works by exposing the local machine port (9090) into the 443 port of the ingress pods
and makes it easy to work without any port-forwading.
It also uses a fixed api server port (16443) so the `kubeconfig` is reusable when you recreate the cluster.

Here's a script to install kind and Ingress and export port 9090 for http and 6443 for https and 16443 for the api server port:

```bash
KIND_EXPERIMENTAL_CONTAINERD_SNAPSHOTTER=native kind create cluster --config - <<EOF
kind: Cluster
name: orchestrator
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 16443
nodes:
  - role: control-plane
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 9090 
        protocol: TCP
      - containerPort: 443
        hostPort: 9443
        protocol: TCP
  - role: worker
EOF

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

# Troubleshooting

Known issues:
- backstage container takes minutes to start (flpath-xxx)

  The problem is with the initcontainer pack/unpack of the various plugins payload.

- pvcs fails to be created or bound

  Run `kubectl get pods -n local-path-storage` and see if an pod is in Error state. 
  The root cause is because the kind node is losing track of the devices on the machine, in case the machine was suspended, disconnected from a docking station (so hardware changed...) or something similar. 
  To overcome that restart the kind control plane node:
  ```
  podman container restart kind-control-plane
  ```
  Make sure to remove the failing containers under local-path-storage.

