# Initialize the GitOps environment
## Install the operators
The `Red Hat OpenShift Pipelines` and `Red Hat OpenShift GitOps` operators can be installed using the solution derived from 
the [Janus IDP Demo](https://github.com/redhat-gpte-devopsautomation/janus-idp-bootstrap)
>This repository contains automation to install the Janus IDP Demo, as well as supporting components

To address the need for including Tekton resources within the ArgoCD applications, a fork has been initiated to remove the exclusion configuration.

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
To allow the Tekton resources to push to the registry, we need an account capable of pushing the image to the registry:

* Create or edit a [Robot account](https://access.redhat.com/documentation/en-us/red_hat_quay/3.3/html/use_red_hat_quay/use-quay-manage-repo) and grant it `Write` permissions to the newly created repository
* Download the `Docker configuration` file for the robot account and move it under the root folder of this repository (we assume the file name is `orchestrator-auth.json`)
* When using a [builder image](https://github.com/parodos-dev/serverless-workflows/blob/main/pipeline/workflow-builder.Dockerfile) for serverless workflows from [registry.redhat.io](registry.redhat.io), it is also required to add also the credential to pull from it as described [here](https://access.redhat.com/terms-based-registry/token/orchestrator/docker-config). Merge the credential into a single file `orchestrator-auth.json` with the credentials from the previous step.
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
* Create a `known_hosts` file by scanning the GitHub's SSH public key:
```console
ssh-keyscan github.com > ssh/known_hosts
```
* Create the default `config` file:
```console
echo "Host github.com
  HostName github.com
  IdentityFile ~/.ssh/id_rsa" > ssh/config
```
* Create the secret that the Pipeline uses to store the SSH credentials:
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
