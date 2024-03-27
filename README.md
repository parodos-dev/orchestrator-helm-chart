## Orchestrator Helm Repository
Helm chart to deploy the Orchestrator solution suite. The following components will be installed on the cluster:
- RHDH (Red Hat Developer Hub) Backstage
- OpenShift Serverless Logic Operator (with Data-Index and Job Service)
- OpenShift Serverless Operator
  - Knative Eventing
  - Knative Serving

## Usage

### Prerequisites
- You logged in to a Red Hat OpenShift Container Platform (version 4.13+) cluster as a cluster administrator.
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) is installed.
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/docs/getting-started/) has been installed in your cluster.
- Your cluster has a [default storage class](https://docs.openshift.com/container-platform/4.13/storage/container_storage_interface/persistent-storage-csi-sc-manage.html) provisioned.
- [Helm](https://helm.sh/docs/intro/install/) v3.9+ is installed.
- [PostgreSQL](https://www.postgresql.org/) database is available with credentials to manage the tablespace.
  - A [reference implementation](#postgresql-deployment-reference-implementation) is provided for your convenience.
- A Github API Token - to import items into the catalog, there is a need for GITHUB_TOKEN with the permissions as detailed [here](https://backstage.io/docs/integrations/github/locations/). For classic token, include at least the following permissions: repo (all), admin:org (read:org) and user (read:user, user:email).

### Deploying PostgreSQL reference implementation
See [here](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

### Installation
Add the repository:
```bash
helm repo add orchestrator https://parodos-dev.github.io/orchestrator-helm-chart
```

Expect result:
```
"orchestrator" has been added to your repositories
```

Verify the repository is shown:
```
helm repo list
```

Expect result:
```
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

#### For non-production purposes, run:
```console
helm install orchestrator orchestrator/orchestrator --set orchestrator.devmode=true \
     --set rhdhOperator.github.token=$GITHUB_TOKEN
```

#### To enable the K8s, Tekton (OpenShift Pipelines), and ArgoCD (OpenShift GitOps) plugins in Backstage, run:
```console
helm install orchestrator orchestrator/orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN \
    --set rhdhOperator.k8s.clusterToken=$K8S_CLUSTER_TOKEN --set rhdhOperator.k8s.clusterUrl=$K8S_CLUSTER_URL \
    --set argocd.namespace=$ARGOCD_NAMESPACE --set argocd.url=$ARGOCD_URL --set argocd.username=$ARGOCD_USERNAME \
    --set argocd.password=$ARGOCD_PASSWORD --set argocd.enabled=true --set tekton.enabled=true
```

### For installing from OpenShift Developer perspective
Create the `HelmChartRepository` from CLI (or from OpenShift UI):
```shell
cat << EOF | oc apply -f -
apiVersion: helm.openshift.io/v1beta1
kind: HelmChartRepository
metadata:
  name: orchestrator
spec:
  connectionConfig:
    url: 'https://parodos-dev.github.io/orchestrator-helm-chart'
EOF
```
Follow Helm Chart installation instructions [here](https://docs.openshift.com/container-platform/4.15/applications/working_with_helm_charts/configuring-custom-helm-chart-repositories.html)

### Workflow installation

Refer to [Workflows Installation](https://www.parodos.dev/serverless-workflows-config/)

### Uninstallation
```console
helm delete orchestrator
release "orchestrator" uninstalled
```

Note that the CRDs created during the installation process will remain in the cluster.
To comprehensively remove the remaining resources, which **cannot** be recovered once deleted, execute the following command:
```console
oc get crd -o name | grep -e 'sonataflow' -e rhdh | xargs oc delete
oc delete pvc --all -n orchestrator
oc delete ns orchestrator
```

## Helm index
[https://parodos-dev.github.io/orchestrator-helm-chart/index.yaml](https://parodos-dev.github.io/orchestrator-helm-chart/index.yaml)
