## Orchestrator Helm Repository
Helm chart to deploy the Orchestrator solution suite. The following components will be installed on the cluster:
- Janus IDP backstage
- SonataFlow Operator (with Data-Index and Job Service)
- OpenShift Serverless Operator
- Knative Eventing
- Knative Serving
- Sample workflow (greeting)
- Move2kube workflow

## Usage

### Prerequisites
- You logged in a Red Hat OpenShift Container Platform (version 4.13+) cluster as a cluster administrator.
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) is installed.
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/docs/getting-started/) has been installed in your cluster.
- Your cluster has a [default storage class](https://docs.openshift.com/container-platform/4.13/storage/container_storage_interface/persistent-storage-csi-sc-manage.html) provisioned.
- [Helm](https://helm.sh/docs/intro/install/) v3.9+ is installed.
- [PostgreSQL](https://www.postgresql.org/) database is avalable with credentials to manage the tablespace.
  - A [reference implementation](#postgresql-deployment-reference-implementation) is provided for your convenience.

### Deploying PostgreSQL reference implementation
Follow these steps to deploy a sample PostgreSQL instance in the `sonataflow-infra` namespace, with minimal requirements to deploy the Orchestrator.
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
$ helm repo add orchestrator https://parodos-dev.github.io/orchestrator-helm-chart
"orchestrator" has been added to your repositories

$ helm repo list
NAME        	URL                                                  
orchestrator	https://parodos-dev.github.io/orchestrator-helm-chart
```

Create a namespace for the Orchestrator solution suite:
```console
$ oc new-project orchestrator-install
```

#### Perform a first pass installation

Replace `backstage.global.clusterRouterBase` with the route of your cluster ingress router.
For example, if the route of your cluster ingress router is `apps.ocp413.lab.local`, then you should 
set `backstage.global.clusterRouterBase=apps.ocp413.lab.local`.

```console
$ helm install orchestrator orchestrator/orchestrator --set backstage.global.clusterRouterBase=apps.ocp413.lab.local
```
Follow the instructions in the output to complete the *first pass* installation.

#### Perform a second pass installation
Using `helm upgrade` with `--set includeCustomResources=true` to deploy the remaining components with custom resources:
```console
$ helm upgrade orchestrator orchestrator/orchestrator --set includeCustomResources=true --set backstage.global.clusterRouterBase=apps.ocp413.lab.local
```

#### Move2kube installation

Refer to [Move2kube installation guide](move2kube/README.md)

### Uninstallation
```console
$ helm upgrade orchestrator orchestrator/orchestrator --set includeCustomResources=false
```
Followed by:
```console
$ helm delete orchestrator
release "orchestrator" uninstalled
```


## Helm index
[https://parodos-dev.github.io/orchestrator-helm-chart/index.yaml](https://parodos-dev.github.io/orchestrator-helm-chart/index.yaml)
