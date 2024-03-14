## Orchestrator Helm Repository
Helm chart to deploy the Orchestrator solution suite. The following components will be installed on the cluster:
- Janus IDP backstage
- SonataFlow Operator (with Data-Index and Job Service)
- OpenShift Serverless Operator
- Knative Eventing
- Knative Serving

## Usage

### Prerequisites
- You logged in a Red Hat OpenShift Container Platform (version 4.13+) cluster as a cluster administrator.
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) is installed.
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/docs/getting-started/) has been installed in your cluster.
- Your cluster has a [default storage class](https://docs.openshift.com/container-platform/4.13/storage/container_storage_interface/persistent-storage-csi-sc-manage.html) provisioned.
- [Helm](https://helm.sh/docs/intro/install/) v3.9+ is installed.
- [PostgreSQL](https://www.postgresql.org/) database is avalable with credentials to manage the tablespace.
  - A [reference implementation](#postgresql-deployment-reference-implementation) is provided for your convenience.
- A Github API Token - in order to import items into the catalog, there is a need for GITHUB_TOKEN with the permissions as detailed [here](https://backstage.io/docs/integrations/github/locations/). For classic token, include at least the following permissions: repo (all), admin:org (read:org) and user (read:user, user:email).

### Deploying PostgreSQL reference implementation
Follow these steps to deploy a sample PostgreSQL instance in the `sonataflow-infra` namespace, with minimal requirements to deploy the Orchestrator.
For non-production mode, skip this step and follow the section under Installation for non-production purpose.

Note: replace the password of the `sonataflow-psql-postgresql` secret below in the following command with the desired one.

```console
git clone git@github.com:parodos-dev/orchestrator-helm-chart.git
cd orchestrator-helm-chart/postgresql
oc new-project sonataflow-infra
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install sonataflow-psql bitnami/postgresql --version 12.x.x -f ./values.yaml
```

Note: the default settings provided in [PostreSQL values](./postgresql/values.yaml) match the defaults provided in the 
[Orchestrator values](./charts/orchestrator/values.yaml). 
Any changes to the first configuration must also be reported in the latter.

### Installation
```
helm repo add orchestrator https://parodos-dev.github.io/orchestrator-helm-chart
"orchestrator" has been added to your repositories

helm repo list
NAME        	URL                                                  
orchestrator	https://parodos-dev.github.io/orchestrator-helm-chart
```

Create a namespace for the Orchestrator solution suite (optional):
```console
oc new-project orchestrator
```

#### Install the chart with Orchestrator plugin and Notifications plugin
This installation expects DB configuration to be provided.
Set value for $GITHUB_TOKEN and run:
```console
helm install orchestrator orchestrator/orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN
```

#### For non-production purpose, run:
```console
helm install orchestrator orchestrator/orchestrator --set orchestrator.devmode=true \
     --set rhdhOperator.github.token=$GITHUB_TOKEN
```

#### To enable the K8s, Tekton (OpenShift Pipelines) and ArgoCD (OpenShift GitOps) plugins in Backstage, run:
```console
helm install orchestrator orchestrator/orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN \
    --set rhdhOperator.k8s.clusterToken=$K8S_CLUSTER_TOKEN --set rhdhOperator.k8s.clusterUrl=$K8S_CLUSTER_URL \
    --set argocd.namespace=$ARGOCD_NAMESPACE --set argocd.url=$ARGOCD_URL --set argocd.username=$ARGOCD_USERNAME \
    --set argocd.password=$ARGOCD_PASSWORD --set argocd.enabled=true --set tekton.enabled=true
```

#### Workflow installation

Refer to [Workflows Installation](https://www.parodos.dev/serverless-workflows-helm/)

### Uninstallation
```console
$ helm upgrade orchestrator orchestrator/orchestrator --set includeCustomResources=false
```
Followed by:
```console
$ helm delete orchestrator
release "orchestrator" uninstalled
```

Note that the CRDs created during the installation process will remain in the cluster. To clean the rest of the resources, run:
```console
oc delete csv sonataflow-operator.v999.0.0-snapshot -n openshift-operators
oc get crd -o name | grep -e 'sonataflow' -e rhdh | xargs oc delete
oc delete pvc --all -n orchestrator
oc delete ns backstage-system
```

## Helm index
[https://parodos-dev.github.io/orchestrator-helm-chart/index.yaml](https://parodos-dev.github.io/orchestrator-helm-chart/index.yaml)
