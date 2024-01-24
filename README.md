## Orchestrator Helm Repository
Helm chart to deploy the Orchestrator solution suite. The following components will be installed on the cluster:
- Janus IDP backstage
- SonataFlow Operator (with Data-Index and Job Service)
- OpenShift Serverless Operator
- Knative Eventing
- Knative Serving
- Sample workflow (greeting)

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

Note: replace the password of the `sonataflow-psql-postgresql` secret below in the following command with the desired one.

```console
oc new-project sonataflow-infra
oc create secret generic sonataflow-psql-postgresql --from-literal=postgres-username=postgres --from-literal=postgres-password=postgres

git clone git@github.com:parodos-dev/orchestrator-helm-chart.git
cd orchestrator-helm-chart/postgresql
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
$ oc new-project orchestrator
$ helm install orchestrator orchestrator/orchestrator
```

### Uninstallation
```console
$ helm delete orchestrator
release "orchestrator" uninstalled
```


## Helm index
[https://parodos-dev.github.io/orchestrator-helm-chart/index.yaml](https://parodos-dev.github.io/orchestrator-helm-chart/index.yaml)
