# Orchestrator Helm Chart
Helm chart to deploy the Orchestrator solution suite on OpenShift, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing and Knative Serving.

This chart will deploy the following on the target OpenShift cluster:
  - Janus IDP backstage
  - SonataFlow Operator (with Data-Index and Job Service)
  - OpenShift Serverless Operator
  - Knative Eventing
  - Knative Serving
  - Sample workflow (greeting)

## Prerequisites
- You logged in a Red Hat OpenShift Container Platform (version 4.13+) cluster as a cluster administrator.
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) is installed.
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/docs/getting-started/) has been installed in your cluster.
- Your cluster has a [default storage class](https://docs.openshift.com/container-platform/4.13/storage/container_storage_interface/persistent-storage-csi-sc-manage.html) provisioned.
- [Helm](https://helm.sh/docs/intro/install/) v3.9+ is installed.
- [PostgreSQL](https://www.postgresql.org/) database is avalable with credentials to manage the tablespace.
  - A [reference implementation](#postgresql-deployment-reference-implementation) is provided for your convenience.
  
Note that as of November 6, 2023, OpenShift Serverless Operator is based on RHEL 8 images which are not supported on the ARM64 architecture. Consequently, deployment of this helm chart on an [OpenShift Local](https://www.redhat.com/sysadmin/install-openshift-local) cluster on Macbook laptops with M1/M2 chips is not supported.

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

For OpenShift-related configuration in the chart visit [here](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/README.md#differences-between-bitnami-postgresql-image-and-docker-official-image).

## Installation

Build helm dependency and create a new project for the installation:
```console
git clone git@github.com:parodos-dev/orchestrator-helm-chart.git
cd orchestrator-helm-chart/charts
helm dep update orchestrator
oc new-project orchestrator
```

Replace `backstage.global.clusterRouterBase` with the route of your cluster ingress router. For example, if the route of
your cluster ingress router is `apps.ocp413.lab.local`, then you should set `backstage.global.clusterRouterBase` to `apps.ocp413.lab.local`.
The value for it can be fetched by:
```console
oc get ingress.config.openshift.io/cluster -oyaml | yq '.spec.domain'
apps.ocp413.lab.local
```

Install the chart:
```console
$ helm install orchestrator orchestrator --set backstage.global.clusterRouterBase=apps.ocp413.lab.local
NAME: orchestrator
LAST DEPLOYED: Tue Jan  2 23:17:54 2024
NAMESPACE: orchestrator
STATUS: deployed
REVISION: 1
USER-SUPPLIED VALUES:
backstage:
  global:
    clusterRouterBase: apps.ocp413.lab.local

Components                   Installed   Namespace
====================================================================
Backstage                    YES        orchestrator
Postgres DB - Backstage      YES        orchestrator
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
  oc wait -n orchestrator pod/orchestrator-postgresql-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator deploy/orchestrator-backstage --for=condition=Available --timeout=5m
  oc wait -n knative-eventing knativeeventing/knative-eventing --for=condition=Ready --timeout=5m
  oc wait -n knative-serving knativeserving/knative-serving --for=condition=Ready --timeout=5m
  oc wait -n sonataflow-infra sonataflow/greeting --for=condition=Running --timeout=5m

deployment.apps/knative-openshift condition met
deployment.apps/sonataflow-operator-controller-manager condition met
deployment.apps/sonataflow-platform-data-index-service condition met
deployment.apps/sonataflow-platform-jobs-service condition met
pod/orchestrator-postgresql-0 condition met
deployment.apps/orchestrator-backstage condition met
knativeeventing.operator.knative.dev/knative-eventing condition met
knativeserving.operator.knative.dev/knative-serving condition met
sonataflow.sonataflow.org/greeting condition met
```

## Testing the Sample Workflow - Greeting

* Retrieve the route of the event timeout workflow service and save it environment variable $ROUTE.
```shell
$ ROUTE=`oc get route event-timeout -n sonataflow-infra -o=jsonpath='{.spec.host}'`
  echo $ROUTE
```
Sample output:
```
event-timeout-sonataflow-infra.apps.cluster-ffmlv.dynamic.opentlc.com
```
* Trigger the timeout workflow and save the workflow id from the response in environment variable $WORKFLOW_ID.
```shell
RESP=`curl -s -i -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -d '{}' 'http://'$ROUTE'/event-timeout'`
WORKFLOW_ID=`echo "$RESP" | awk '/^\{/,/\}$/ {print}' | jq -r '.id'`
echo $WORKFLOW_ID
```
* Sample response
```
6f80f479-1a5d-4bfb-8e2e-faaba76d0b63
```

* Run the following two commands within 60 seconds of the command above, as the workflow timeout is 60s. 
* Trigger event1:
```shell
curl -i -X POST -H 'Content-Type: application/json' -d '{"datacontenttype": "application/json", "specversion":"1.0","id":"'${WORKFLOW_ID}'","source":"/local/curl","type":"event1_event_type","data": "{\"eventData\":\"Event1 sent from Command Line\"}", "kogitoprocrefid": "'${WORKFLOW_ID}'" }' http://$ROUTE
```

* Sample response
```json
HTTP/1.1 202 Accepted
content-length: 0
set-cookie: da54ae0c1dede48a1bd1b52c3620cecc=bf774cafeae884d8642fba7b3e7e16f0; path=/; HttpOnly
```

* Trigger event2:
```shell
curl -i -X POST -H 'Content-Type: application/json' -d '{"datacontenttype": "application/json", "specversion":"1.0","id":"'${WORKFLOW_ID}'","source":"/local/curl","type":"event2_event_type","data": "{\"eventData\":\"Event2 sent from Command Line\"}", "kogitoprocrefid": "'${WORKFLOW_ID}'" }' http://$ROUTE
```

* Sample response
```json
HTTP/1.1 202 Accepted
content-length: 0
set-cookie: da54ae0c1dede48a1bd1b52c3620cecc=bf774cafeae884d8642fba7b3e7e16f0; path=/; HttpOnly
```

## Cleanup
To remove the installation from the cluster, run:
```console
$ helm delete orchestrator
release "orchestrator" uninstalled
```
Note that the CRDs created during the installation process will remain in the cluster.

## Development
The [Helm Chart Documentation](./charts/orchestrator/README.md) is generated by the [frigate tool](https://github.com/rapidsai/frigate). After the tool is installed, you can run the following command to re-generate the chart documentation.
```console
$ cd charts/orchestrator
$ frigate gen --no-deps . > README.md
```

## Documentation
See [Helm Chart Documentation](./charts/orchestrator/README.md) for information about the values used by the helm chart.

This helm chart uses the [Janus-IDP backstage helm chart](https://github.com/janus-idp/helm-backstage) as a dependency subchart. See the [chart documentation](https://github.com/janus-idp/helm-backstage/blob/main/charts/backstage/README.md) on how to override its values. 