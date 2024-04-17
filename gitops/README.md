# Initialize the GitOps environment

## Install the operators

The `Red Hat OpenShift Pipelines` and `Red Hat OpenShift GitOps` operators can be installed from the solution
derived from the [Janus IDP Demo](https://github.com/redhat-gpte-devopsautomation/janus-idp-bootstrap)

> This repository contains automation to install the Janus IDP Demo, as well as supporting components

A fork has been created to remove the configuration that excludes Tekton resources from being configured from the
ArgoCD applications (see [discussion](https://github.com/argoproj/argo-cd/discussions/8674#discussioncomment-2318554)).

First, install the `Red Hat OpenShift Pipelines` operator:

```bash
git clone https://github.com/parodos-dev/janus-idp-bootstrap.git
cd janus-idp-bootstrap/charts
helm upgrade --install orchestrator-pipelines pipelines-operator/ -f pipelines-operator/values.yaml -n orchestrator-gitops --create-namespace
```

Finally, install and configure the `Red Hat OpenShift GitOps` operator:

```bash
helm upgrade --install orchestrator-gitops gitops-operator/ -f gitops-operator/values.yaml -n orchestrator-gitops --create-namespace --set namespaces={orchestrator-gitops}
```

## Installing docker credentials

The Tekton pipeline deployed by the Orchestrator is responsible for building a workflow image and pushing it to Quay.io.
There is a need to create a single K8s secret combined with the following secrets:
1. A secret for Quay.io organization to push the images built by the pipeline:
   - Create or edit a [Robot account](https://access.redhat.com/documentation/en-us/red_hat_quay/3.3/html/use_red_hat_quay/use-quay-manage-repo) and grant it `Write` permissions to the newly created repository
   - Download the credentials as Kubernetes secret.
2. A secret for [registry.redhat.io](registry.redhat.io). To build workflow images, the pipeline uses the [builder image](https://github.com/parodos-dev/serverless-workflows/blob/main/pipeline/workflow-builder.Dockerfile) from [registry.redhat.io](registry.redhat.io).
   - Generate a token [here](https://access.redhat.com/terms-based-registry/create), and download it as OCP secret.

Those two K8s secrets should be merged into a single secret named `docker-credentials` in `orchestrator-gitops` namespace in the cluster that runs the pipelines.
You may use this [helper script](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/hack/merge_secrets.sh) to merge the secrets or choose another method of downloading the credentials and merging them.

## Define the SSH credentials

The pipeline uses SSH to push the deployment configuration to the `gitops` repository containing the `kustomize` deployment configuration.

Follow these steps to properly configure the credentials in the namespace:

- Generate default SSH keys under the `ssh` folder

```console
mkdir -p ssh
ssh-keygen -t rsa -b 4096 -f ssh/id_rsa -N "" -C git@github.com -q
```

- Add the SSH key to your GitHub account using the gh CLI or using the [SSH keys](https://github.com/settings/keys) setting:

```console
gh ssh-key add ssh/id_rsa.pub --title "Tekton pipeline"
```

- Create a `known_hosts` file by scanning the GitHub's SSH public key:

```console
ssh-keyscan github.com > ssh/known_hosts
```

- Create the default `config` file:

```console
echo "Host github.com
  HostName github.com
  IdentityFile ~/.ssh/id_rsa" > ssh/config
```

- Create the secret that the Pipeline uses to store the SSH credentials:

```console
oc create secret -n orchestrator-gitops generic git-ssh-credentials \
  --from-file=ssh/id_rsa \
  --from-file=ssh/config \
  --from-file=ssh/known_hosts
```

Note: if you change the SSH key type from the default value `rsa`, you need to update the `config` file accordingly

## Setting up GitHub Integration

To begin serverless workflow development using the "Basic workflow bootstrap project" software template with GitHub as the target source control, you'll need to configure organization settings to allow read and write permissions for GitHub workflows. Follow these steps to enable the necessary permissions:

1. Navigate to your organization settings on GitHub.
2. Locate the section for managing organization settings related to GitHub Actions.
3. Enable read and write permissions for workflows by adjusting the settings accordingly.
4. For detailed instructions and exact steps, refer to the GitHub guide available [here](https://docs.github.com/en/enterprise-server@3.9/organizations/managing-organization-settings/disabling-or-limiting-github-actions-for-your-organization#configuring-the-default-github_token-permissions).
