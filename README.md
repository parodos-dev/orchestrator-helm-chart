# Orchestrator Helm Chart
Helm chart to deploy the Orchestrator solution suite on OpenShift or Kubernetes, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing and Knative Serving.

All the instruction here are relevant for installation on OpenShift. For installing on Kubernetes see [INSTALL-k8s.md](INSTALL-k8s.md)

This chart will deploy the following on the target OpenShift cluster:
  - Janus IDP backstage
  - SonataFlow Operator (with Data-Index and Job Service)
  - OpenShift Serverless Operator
  - Knative Eventing
  - Knative Serving
  - Sample workflow (greeting)

## Prerequisites
- You logged in to a Red Hat OpenShift Container Platform (version 4.13+) cluster as a cluster administrator.
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) is installed.
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/docs/getting-started/) has been installed in your cluster.
- Your cluster has a [default storage class](https://docs.openshift.com/container-platform/4.13/storage/container_storage_interface/persistent-storage-csi-sc-manage.html) provisioned.
- [Helm](https://helm.sh/docs/intro/install/) v3.9+ is installed.
- [PostgreSQL](https://www.postgresql.org/) database is available with credentials to manage the tablespace (optional).
  - A [reference implementation](#postgresql-deployment-reference-implementation) is provided for your convenience.
- A Github API Token - in order to import items into the catalog, there is a need for GITHUB_TOKEN with the permissions as detailed [here](https://backstage.io/docs/integrations/github/locations/). For classic token, include the following permissions: repo (all), admin:org (read:org) and user (read:user, user:email).
  
Note that as of November 6, 2023, OpenShift Serverless Operator is based on RHEL 8 images which are not supported on the ARM64 architecture. Consequently, deployment of this helm chart on an [OpenShift Local](https://www.redhat.com/sysadmin/install-openshift-local) cluster on Macbook laptops with M1/M2 chips is not supported.

### Deploying PostgreSQL reference implementation
Follow these steps to deploy a sample PostgreSQL instance in the `sonataflow-infra` namespace, with minimal requirements to deploy the Orchestrator.
This step is optional and can be replaced with running the orchestrator chart in devmode which uses ephemeral images for sonataflow services.

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

For OpenShift-related configuration in the chart visit [here](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/README.md#differences-between-bitnami-postgresql-image-and-docker-official-image).

## Installation

Build helm dependency and create a new project for the installation:
```console
git clone git@github.com:parodos-dev/orchestrator-helm-chart.git
cd orchestrator-helm-chart/charts
oc new-project orchestrator
```

Install the chart (expects DB configuration to be provided), set value for $GITHUB_TOKEN:
```console
$ helm install orchestrator orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN
```
or install sonataflow services in ephemeral mode for evaluation purposes:
```console
$ helm install orchestrator orchestrator --set orchestrator.devmode=true \
    --set rhdhOperator.github.token=$GITHUB_TOKEN
```

To enable the K8s and Tekton (OpenShift Pipelines) plugins in Backstage, install by:
```console
$ helm install orchestrator orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN \
    --set rhdhOperator.k8s.clusterToken=$K8S_CLUSTER_TOKEN --set rhdhOperator.k8s.clusterUrl=$K8S_CLUSTER_URL
```
The $K8S_CLUSTER_TOKEN should provide access to resources as detailed [here](https://github.com/janus-idp/backstage-plugins/tree/main/plugins/tekton#prerequisites) and $K8S_CLUSTER_URL from the output of `oc cluster-info` (API server URL, e.g. https://api.cluster-domain:6443).


A sample output:
```
NAME: orchestrator
LAST DEPLOYED: Tue Jan  2 23:17:54 2024
NAMESPACE: orchestrator
STATUS: deployed
REVISION: 1
USER-SUPPLIED VALUES:

Components                   Installed   Namespace
====================================================================
Backstage                    YES        backstage-system
Postgres DB - Backstage      NO         backstage-system
Red Hat Serverless Operator  YES        openshift-serverless
KnativeServing               YES        knative-serving
KnativeEventing              YES        knative-eventing
SonataFlow Operator          YES        openshift-operators
SonataFlowPlatform           YES        sonataflow-infra
Data Index Service           YES        sonataflow-infra
Job Service                  YES        sonataflow-infra

Workflows deployed on namespace sonataflow-infra:
greeting
```

Run the following commands to wait until the services are ready:
```console
  oc wait -n openshift-serverless deploy/knative-openshift --for=condition=Available --timeout=5m
  oc wait -n openshift-operators deploy/sonataflow-operator-controller-manager --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/sonataflow-platform-data-index-service --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/sonataflow-platform-jobs-service --for=condition=Available --timeout=5m
  oc wait -n backstage-system pod/backstage-psql-backstage-0 --for=condition=Ready --timeout=5m
  oc wait -n backstage-system backstage backstage --for=condition=Deployed=True
  oc wait -n backstage-system deploy/backstage-backstage --for=condition=Available --timeout=5m
  oc wait -n knative-eventing knativeeventing/knative-eventing --for=condition=Ready --timeout=5m
  oc wait -n knative-serving knativeserving/knative-serving --for=condition=Ready --timeout=5m
  oc wait -n sonataflow-infra sonataflow/greeting --for=condition=Running --timeout=5m

deployment.apps/knative-openshift condition met
deployment.apps/sonataflow-operator-controller-manager condition met
deployment.apps/sonataflow-platform-data-index-service condition met
deployment.apps/sonataflow-platform-jobs-service condition met
pod/backstage-psql-backstage-0 condition met
backstage.rhdh.redhat.com/backstage condition met
deployment.apps/backstage-backstage condition met
knativeeventing.operator.knative.dev/knative-eventing condition met
knativeserving.operator.knative.dev/knative-serving condition met
sonataflow.sonataflow.org/greeting condition met
```

### Workflow installation

Follow [Workflows Installation](https://www.parodos.dev/serverless-workflows-helm/)

### Installation from OpenShift
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

## Testing the Sample Workflow - Greeting

* Retrieve the route of the Greeting workflow service and save it environment variable $ROUTE.
```shell
$ ROUTE=`oc get route greeting -n sonataflow-infra -o=jsonpath='{.spec.host}'`
  echo $ROUTE
```
Sample output:
```
greeting-sonataflow-infra.apps.ocp413.lab.local
```
* Trigger the greeting workflow and save the workflow ID from the response in the environment variable $WORKFLOW_ID.
```shell
curl -s -k -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -d '{ "language": "Spanish" }' 'https://'$ROUTE'/greeting' | jq
```
* Sample response
```
{
  "id": "9cb41281-f827-4d66-aaa8-76ca2d0fb9e0",
  "workflowdata": {
    "language": "Spanish",
    "greeting": "Saludos desde YAML Workflow, "
  }
}
```

## Cleanup
To remove the installation from the cluster, run:
```console
$ helm delete orchestrator
release "orchestrator" uninstalled
```
Note that the CRDs created during the installation process will remain in the cluster.
To clean the rest of the resources, run:
```console
oc delete csv sonataflow-operator.v999.0.0-snapshot -n openshift-operators
oc get crd -o name | grep -e 'sonataflow' -e rhdh | xargs oc delete
oc delete pvc --all -n orchestrator
oc delete ns backstage-system
```

## Development
The [Helm Chart Documentation](./charts/orchestrator/README.md) is generated by the [frigate tool](https://github.com/rapidsai/frigate). After the tool is installed, you can run the following command to re-generate the chart documentation.
```console
$ cd charts/orchestrator
$ frigate gen --no-deps . > README.md
```

### Updating plugins version
The Orchestrator includes the orchestrator and the notification plugins.
Overall, there are 4 plugins:
* [notifications](https://github.com/janus-idp/backstage-plugins/tree/main/plugins/notifications) - [@janus-idp/plugin-notifications](https://www.npmjs.com/package/@janus-idp/plugin-notifications) in npmjs
* [notifications-backend](https://github.com/janus-idp/backstage-plugins/tree/main/plugins/notifications-backend) - [@janus-idp/plugin-notifications-backend-dynamic](https://www.npmjs.com/package/@janus-idp/plugin-notifications-backend-dynamic) in npmjs
* [orchestrator](https://github.com/janus-idp/backstage-plugins/tree/main/plugins/orchestrator) - [@janus-idp/backstage-plugin-orchestrator](https://www.npmjs.com/package/@janus-idp/backstage-plugin-orchestrator) in npmjs
* [orchestrator-backend](https://github.com/janus-idp/backstage-plugins/tree/main/plugins/orchestrator-backend) - [@janus-idp/backstage-plugin-orchestrator-backend-dynamic](https://www.npmjs.com/package/@janus-idp/backstage-plugin-orchestrator-backend-dynamic) in npmjs

The plugins are configured by the `dynamic-plugins-rhdh` configmap in [RHDH operator configuration](./charts/orchestrator/templates/rhdh-operator.yaml).
To update plugin versions, use the npmjs package name, use the script: [./hack/update_plugins_version.sh](./hack/update_plugins_version.sh)

## Documentation
See [Helm Chart Documentation](./charts/orchestrator/README.md) for information about the values used by the helm chart.
