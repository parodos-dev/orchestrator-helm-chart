# Initialize the GitOps environment
## Install the operators
The `Red Hat OpenShift Pipelines` and `Red Hat OpenShift GitOps` operators can be installed from the solution 
derived from the [Janus IDP Demo](https://github.com/redhat-gpte-devopsautomation/janus-idp-bootstrap)
>This repository contains automation to install the Janus IDP Demo, as well as supporting components

A fork has been created to remove the configuration that excludes Tekton resources from being configured from the 
ArgoCD applications (see [discussion](https://github.com/argoproj/argo-cd/discussions/8674#discussioncomment-2318554)).

First, install the `Red Hat OpenShift Pipelines` operator:
```console
git clone https://github.com/parodos-dev/janus-idp-bootstrap.git
cd charts/pipelines-operator
helm upgrade --install orchestrator-pipelines . -f values.yaml -n orchestrator-gitops --create-namespace
```

Finally install and configure the `Red Hat OpenShift GitOps` operator:
```console
git clone https://github.com/parodos-dev/janus-idp-bootstrap.git
cd charts/gitops-operator
helm upgrade --install orchestrator-gitops . -f values.yaml -n orchestrator-gitops --create-namespace --set namespaces={orchestrator-gitops}
```

## Installing docker credentials
To allow the Tekton resources to push to the registry, we need an account capable to push the image to the registry:

* Create or edit a [Robot account](https://access.redhat.com/documentation/en-us/red_hat_quay/3.3/html/use_red_hat_quay/use-quay-manage-repo) and grant it `Write` permissions to the newly created repository
* Download `the Docker configuration` file for the robot account and move it under the root folder of this repository (we assume the file name is `orchestrator-auth.json`)
* Run the following to create the `docker-credentials` secret:
```console
oc create secret -n orchestrator-gitops generic docker-credentials --from-file=config.json=orchestrator-auth.json
```

## Define the SSH credentials
The pipeline uses SSH to push the deployment configuration to the `gitops` repository containing the `kustomize` deployment configuration.

Follow these steps to properly configure the credentials in the namespace:

* Generate default SSH keys under the `ssh` folder
```console
mkdir -p ssh
ssh-keygen -t rsa -b 4096 -f ssh/id_rsa -N "" -C git@github.com -q
```
* Add the SSH key to your GitHub account using the gh CLI or using the [SSH keys](https://github.com/settings/keys) setting:
```console
gh ssh-key add ssh/id_rsa.pub --title "Tekton pipeline"
```
* Create a `known_hosts` file by scanning the
```console
ssh-keyscan github.com > ssh/known_hosts
```
* Create the default `config` file:
```console
echo "Host github.com
  HostName github.com
  IdentityFile ~/.ssh/id_rsa" > ssh/config
```
* Create the secret used by the Pipeline to store the SSH credentials:
```console
oc create secret -n orchestrator-gitops generic git-ssh-credentials \
  --from-file=ssh/id_rsa \
  --from-file=ssh/config \
  --from-file=ssh/known_hosts
```
Note: if you change the SSH key type from the default value `rsa`, you need to update the `config` file accordingly