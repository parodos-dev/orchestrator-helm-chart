# Orchestrator Helm Chart
Helm chart to deploy the Orchestrator solution suite. The following components will be installed on the cluster:

This chart will deploy the following on the target OpenShift cluster:
- RHDH (Red Hat Developer Hub) Backstage
- OpenShift Serverless Logic Operator (with Data-Index and Job Service)
- OpenShift Serverless Operator
  - Knative Eventing
  - Knative Serving
- ArgoCD `orchestrator` project (optional: disabled by default)
- Tekton tasks and build pipeline (optional: disabled by default)

## Prerequisites
- You logged in to a Red Hat OpenShift Container Platform (version 4.13+) cluster as a cluster administrator.
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) is installed.
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/docs/getting-started/) has been installed in your cluster.
- Your cluster has a [default storage class](https://docs.openshift.com/container-platform/4.13/storage/container_storage_interface/persistent-storage-csi-sc-manage.html) provisioned.
- [Helm](https://helm.sh/docs/intro/install/) v3.9+ is installed.
- [PostgreSQL](https://www.postgresql.org/) database is available with credentials to manage the tablespace (optional).
  - A [reference implementation](#postgresql-deployment-reference-implementation) is provided for your convenience.
- A Github API Token - to import items into the catalog, there is a need for GITHUB_TOKEN with the permissions as detailed [here](https://backstage.io/docs/integrations/github/locations/). For classic token, include the following permissions: repo (all), admin:org (read:org) and user (read:user, user:email).
- `ArgoCD/OpenShift GitOps` operator is installed and one instance of `ArgoCD` exists in a given namespace (later referenced by `ARGOCD_NAMESPACE` env var)
  - Validated API is `argoproj.io/v1alpha1/AppProject`
- `Tekton/OpenShift Pipelines` operator is installed in the orchestrator namespace (e.g. `orchestrator.namespace` release value)
  - Validated APIs are `tekton.dev/v1beta1/Task` and `tekton.dev/v1/Pipeline`

Note that as of November 6, 2023, OpenShift Serverless Operator is based on RHEL 8 images which are not supported on the ARM64 architecture. Consequently, deployment of this helm chart on an [OpenShift Local](https://www.redhat.com/sysadmin/install-openshift-local) cluster on Macbook laptops with M1/M2 chips is not supported.

### GitOps environment
See the dedicated [document](./GitOps.md)

### Deploying PostgreSQL reference implementation
See [here](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

## Installation
**Note: ArgoCD and workflow namespace**
If you manually created the workflow namespaces (e.g., $WORKFLOW_NAMESPACE), run this command to add the required label that allows
ArgoCD deploying instances there:
```console
oc label ns $WORKFLOW_NAMESPACE argocd.argoproj.io/managed-by=$ARGOCD_NAMESPACE
```

Build helm dependency and create a new project for the installation:
```console
git clone git@github.com:parodos-dev/orchestrator-helm-chart.git
cd orchestrator-helm-chart/charts
oc new-project orchestrator
```

### Install the chart with Orchestrator plugin and Notifications plugin
This installation expects DB configuration to be provided.
Set value for $GITHUB_TOKEN and run:
```console
helm install orchestrator orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN
```

### Install the chart with sonataflow services in ephemeral mode for evaluation purposes
```console
helm install orchestrator orchestrator --set orchestrator.devmode=true \
  --set rhdhOperator.github.token=$GITHUB_TOKEN
```

### Install the chart with enabling the K8s, Tekton (OpenShift Pipelines) and ArgoCD (OpenShift GitOps) plugins in Backstage:
```console
helm install orchestrator orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN \
  --set rhdhOperator.k8s.clusterToken=$K8S_CLUSTER_TOKEN --set rhdhOperator.k8s.clusterUrl=$K8S_CLUSTER_URL \
  --set argocd.namespace=$ARGOCD_NAMESPACE --set argocd.url=$ARGOCD_URL --set argocd.username=$ARGOCD_USERNAME \
  --set argocd.password=$ARGOCD_PASSWORD --set argocd.enabled=true --set tekton.enabled=true
```
The $K8S_CLUSTER_TOKEN should provide access to resources as detailed [here](https://github.com/janus-idp/backstage-plugins/tree/main/plugins/tekton#prerequisites) and $K8S_CLUSTER_URL from the output of `oc cluster-info` (API server URL, e.g. https://api.cluster-domain:6443).

A sample output:
```
NAME: orchestrator
LAST DEPLOYED: Thu Mar 21 14:31:09 2024
NAMESPACE: orchestrator
STATUS: deployed
REVISION: 1
TEST SUITE: None
USER-SUPPLIED VALUES:

Components                   Installed   Namespace
====================================================================
Backstage                    YES        rhdh-operator
Postgres DB - Backstage      NO         rhdh-operator
Red Hat Serverless Operator  YES        openshift-serverless
KnativeServing               YES        knative-serving
KnativeEventing              YES        knative-eventing
SonataFlow Operator          YES        openshift-serverless-logic
SonataFlowPlatform           YES        sonataflow-infra
Data Index Service           YES        sonataflow-infra
Job Service                  YES        sonataflow-infra
Tekton pipeline              NO         sonataflow-infra
Tekton task                  NO         sonataflow-infra
ArgoCD project               NO         argocd

====================================================================
Prerequisites check:
The required CRD tekton.dev/v1beta1/Task is already installed.
The required CRD tekton.dev/v1/Pipeline is already installed.
WARN: CRD for argoproj.io/v1alpha1/AppProject is not installed
====================================================================


Run the following commands to wait until the services are ready:
  oc wait -n openshift-serverless deploy/knative-openshift --for=condition=Available --timeout=5m
  oc wait -n knative-eventing knativeeventing/knative-eventing --for=condition=Ready --timeout=5m
  oc wait -n knative-serving knativeserving/knative-serving --for=condition=Ready --timeout=5m
  oc wait -n openshift-serverless-logic deploy/logic-operator-rhel8-controller-manager --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra sonataflowplatform/sonataflow-platform --for=condition=Succeed --timeout=5m
  oc wait -n sonataflow-infra deploy/sonataflow-platform-data-index-service --for=condition=Available --timeout=5m
  oc wait -n sonataflow-infra deploy/sonataflow-platform-jobs-service --for=condition=Available --timeout=5m
  oc wait -n rhdh-operator backstage backstage --for=condition=Deployed=True
  oc wait -n rhdh-operator deploy/backstage-backstage --for=condition=Available --timeout=5m

In case of a CR deployment failure, check the logs of the pods created by the corresponding job to deploy the failed CRs instance. The jobs are always
deleted after the deployment of the chart is completed.
```

Run the commands to wait until the services are ready should produce the following output:
```console
deployment.apps/knative-openshift condition met
knativeeventing.operator.knative.dev/knative-eventing condition met
knativeserving.operator.knative.dev/knative-serving condition met
deployment.apps/logic-operator-rhel8-controller-manager condition met
sonataflowplatform.sonataflow.org/sonataflow-platform condition met
deployment.apps/sonataflow-platform-data-index-service condition met
deployment.apps/sonataflow-platform-jobs-service condition met
backstage.rhdh.redhat.com/backstage condition met
deployment.apps/backstage-backstage condition met
```

### Workflow installation

Follow [Workflows Installation](https://www.parodos.dev/serverless-workflows-config/)

## Cleanup
To remove the installation from the cluster, run:
```console
helm delete orchestrator
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
cd charts/orchestrator
frigate gen --no-deps . > README.md
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
