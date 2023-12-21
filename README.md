# Orchestrator Helm Chart
Helm chart to deploy the Orchestrator solution suite on OpenShift, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing, Knative Serving, Data Index and Job Service.

This chart will deploy the following on the target OpenShift cluster:
  - Janus IDP backstage
  - SonataFlow Operator
  - OpenShift Serverless Operator
  - Knative Eventing
  - Knative Serving
  - Data Index Service
  - Job Service
  - PostgreSQL Databases 
  - Sample workflow (event-timeout)

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

## Installation

This helm chart deploys OpenShift Serverless Operator and SonataFlow operator as well as other components using custom resources (eg, KnativeEventing, KnativeServing CRs, SonataFlow, SonataFlowPlatform, etc) for the CRDs supported by these operators. Because the custom resources can only be deployed after the corresponding CRDs for the operator have been created and registered with the Kubernetes API Server, we use a two-phase deployment process as follows.

Build helm dependency and create a new project for the installation:
```console
git clone git@github.com:parodos-dev/orchestrator-helm-chart.git
cd orchestrator-helm-chart/charts
helm dep update orchestrator
oc new-project orchestrator-install
```
Perform a first pass installation:
```console
Replace `backstage.global.clusterRouterBase` with the route of your cluster ingress router. For example, if the route of
your cluster ingress router is `apps.ocp413.lab.local`, then you should set `backstage.global.clusterRouterBase=apps.ocp413.lab.local`.

$ helm install orchestrator orchestrator --set backstage.global.clusterRouterBase=apps.ocp413.lab.local
NAME: orchestrator
LAST DEPLOYED: Tue Nov  7 21:04:36 2023
NAMESPACE: orchestrator-install
STATUS: deployed
REVISION: 1
NOTES:
Helm Release orchestrator installed in namespace orchestrator-install.

Components                   Installed   Namespace
====================================================================
Backstage                    YES        orchestrator-install
Postgres DB - Backstage      YES        orchestrator-install
Red Hat Serverless Operator  YES        openshift-serverless
KnativeServing               NO         knative-serving
KnativeEventing              NO         knative-eventing
SonataFlow Operator          YES        openshift-operators
SonataFlowPlatform           NO         sonataflow-infra
Data Index Service           YES        sonataflow-infra
Job Service                  YES        sonataflow-infra
Postgres DB - workflows      YES        sonataflow-infra

No workflows deployed.

Run the following commands to wait until the services are ready:
  oc wait -n openshift-serverless deploy/knative-openshift --for=condition=Available --timeout=5m
  oc wait -n openshift-operators deploy/sonataflow-operator-controller-manager --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/data-index --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/jobs-service --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra pod/postgres-db-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator-install pod/orchestrator-postgresql-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator-install deploy/orchestrator-backstage --for=condition=Available --timeout=5m
```
Now wait for at least 5 minutes and use commands below to check if the CRDs have been created in the cluster before proceeding to the next step.
```console
$ oc get crd | grep operator.knative.dev
knativeeventings.operator.knative.dev                             2023-11-06T16:13:22Z
knativeservings.operator.knative.dev                              2023-11-06T16:13:22Z
```
```console
$ oc get crd | grep sonataflow.org
sonataflowbuilds.sonataflow.org                                   2023-11-06T16:13:08Z
sonataflowplatforms.sonataflow.org                                2023-11-06T16:13:08Z
sonataflows.sonataflow.org                                        2023-11-06T16:13:08Z
```
Now, perform a 2nd pass installation using `helm upgrade` with `--set includeCustomResources=true` to deploy the remaining components with custom resources:
```console
$ helm upgrade orchestrator orchestrator --set includeCustomResources=true --set backstage.global.clusterRouterBase=apps.ocp413.lab.local
Release "orchestrator" has been upgraded. Happy Helming!
NAME: orchestrator
LAST DEPLOYED: Tue Nov  7 21:06:40 2023
NAMESPACE: orchestrator-install
STATUS: deployed
REVISION: 2
NOTES:
Helm Release orchestrator installed in namespace orchestrator-install.

Components                   Installed   Namespace
====================================================================
Backstage                    YES        orchestrator-install
Postgres DB - Backstage      YES        orchestrator-install
Red Hat Serverless Operator  YES        openshift-serverless
KnativeServing               YES        knative-serving
KnativeEventing              YES        knative-eventing
SonataFlow Operator          YES        openshift-operators
SonataFlowPlatform           YES        sonataflow-infra
Data Index Service           YES        sonataflow-infra
Job Service                  YES        sonataflow-infra
Postgres DB - workflows      YES        sonataflow-infra

Workflows deployed on namespace sonataflow-infra:
event-timeout

Run the following commands to wait until the services are ready:
  oc wait -n openshift-serverless deploy/knative-openshift --for=condition=Available --timeout=5m
  oc wait -n knative-eventing knativeeventing/knative-eventing --for=condition=Ready --timeout=5m
  oc wait -n knative-serving knativeserving/knative-serving --for=condition=Ready --timeout=5m
  oc wait -n openshift-operators deploy/sonataflow-operator-controller-manager --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra sonataflowplatform/sonataflow-platform --for=condition=Succeed --timeout=5m
  oc wait -n sonataflow-infra deploy/data-index --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/jobs-service --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra pod/postgres-db-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator-install pod/orchestrator-postgresql-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator-install deploy/orchestrator-backstage --for=condition=Available --timeout=5m

Run the following commands to wait until the workflow builds are done and workflows are running on namespace sonataflow-infra:
  oc wait -n sonataflow-infra sonataflow/event-timeout --for=condition=Built --timeout=15m
  oc wait -n sonataflow-infra sonataflow/event-timeout --for=condition=Running --timeout=5m
```
Wait and watch for the deployed components to be up and running. You will notice that a pod `event-timeout-1-build` will start running. SonataFlow operator uses this pod to build and push the images for the event-timout workflow into the local registry. Be patient, as this can take 10 to 20 minutes. Once it is done another pod for the workflow gets started. 
```console
$ oc wait -n openshift-serverless deploy/knative-openshift --for=condition=Available --timeout=5m
  oc wait -n knative-eventing knativeeventing/knative-eventing --for=condition=Ready --timeout=5m
  oc wait -n knative-serving knativeserving/knative-serving --for=condition=Ready --timeout=5m
  oc wait -n openshift-operators deploy/sonataflow-operator-controller-manager --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra sonataflowplatform/sonataflow-platform --for=condition=Succeed --timeout=5m
  oc wait -n sonataflow-infra deploy/data-index --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/jobs-service --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra pod/postgres-db-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator-install pod/orchestrator-postgresql-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator-install deploy/orchestrator-backstage --for=condition=Available --timeout=5m

deployment.apps/knative-openshift condition met
knativeeventing.operator.knative.dev/knative-eventing condition met
knativeserving.operator.knative.dev/knative-serving condition met
deployment.apps/sonataflow-operator-controller-manager condition met
sonataflowplatform.sonataflow.org/sonataflow-platform condition met
deployment.apps/data-index condition met
deployment.apps/jobs-service condition met
pod/postgres-db-0 condition met
pod/orchestrator-postgresql-0 condition met
deployment.apps/orchestrator-backstage condition met
```
Run the following commands to wait until the workflow builds are done and workflows are running:
```console
$ oc wait -n sonataflow-infra sonataflow/event-timeout --for=condition=Built --timeout=15m
  oc wait -n sonataflow-infra sonataflow/event-timeout --for=condition=Running --timeout=5m

sonataflow.sonataflow.org/event-timeout condition met
sonataflow.sonataflow.org/event-timeout condition met
```
## Testing the Sample Workflow - Event Timeout

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
To remove the installation from the cluster, first remove the deployed custom resources using `helm upgrade` as below.
```console
$ helm upgrade orchestrator orchestrator --set includeCustomResources=false
Release "orchestrator" has been upgraded. Happy Helming!
NAME: orchestrator
LAST DEPLOYED: Tue Nov  7 21:24:04 2023
NAMESPACE: orchestrator-install
STATUS: deployed
REVISION: 3
NOTES:
Helm Release orchestrator installed in namespace orchestrator-install.

Components                   Installed   Namespace
====================================================================
Backstage                    YES        orchestrator-install
Postgres DB - Backstage      YES        orchestrator-install
Red Hat Serverless Operator  YES        openshift-serverless
KnativeServing               NO         knative-serving
KnativeEventing              NO         knative-eventing
SonataFlow Operator          YES        openshift-operators
SonataFlowPlatform           NO         sonataflow-infra
Data Index Service           YES        sonataflow-infra
Job Service                  YES        sonataflow-infra
Postgres DB - workflows      YES        sonataflow-infra

No workflows deployed.

Run the following commands to wait until the services are ready:
  oc wait -n openshift-serverless deploy/knative-openshift --for=condition=Available --timeout=5m
  oc wait -n openshift-operators deploy/sonataflow-operator-controller-manager --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/data-index --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/jobs-service --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra pod/postgres-db-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator-install pod/orchestrator-postgresql-0 --for=condition=Ready --timeout=5m
  oc wait -n orchestrator-install deploy/orchestrator-backstage --for=condition=Available --timeout=5m
```
Wait until the following custom resources have been completely deleted before proceeding.
```console
$ oc get knativeeventing -n knative-eventing
No resources found in knative-eventing namespace.
$ oc get knativeserving -n knative-serving
No resources found in knative-serving namespace.
$ oc get sonataflow -n sonataflow-infra
No resources found in sonataflow-infra namespace.
$ oc get sonataflowplatform -n sonataflow-infra
No resources found in sonataflow-infra namespace.
```
Now you can clean up the remaining components.
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