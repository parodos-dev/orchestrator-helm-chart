# Orchestrator Helm Chart
Deploy the Orchestrator solution suite using this Helm chart.
The chart installs the following components onto the target OpenShift cluster:

This chart will deploy the following on the target OpenShift cluster:
- RHDH (Red Hat Developer Hub) Backstage
- OpenShift Serverless Logic Operator (with Data-Index and Job Service)
- OpenShift Serverless Operator
  - Knative Eventing
  - Knative Serving
- ArgoCD `orchestrator` project (optional: disabled by default)
- Tekton tasks and build pipeline (optional: disabled by default)

## Important Note for ARM64 Architecture Users
Note that as of November 6, 2023, OpenShift Serverless Operator is based on RHEL 8 images which are not supported on the ARM64 architecture. Consequently, deployment of this helm chart on an [OpenShift Local](https://www.redhat.com/sysadmin/install-openshift-local) cluster on MacBook laptops with M1/M2 chips is not supported.

## Prerequisites
- Logged in to a Red Hat OpenShift Container Platform (version 4.13+) cluster as a cluster administrator.
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) is installed.
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/docs/getting-started/) has been installed in your cluster.
- Your cluster has a [default storage class](https://docs.openshift.com/container-platform/4.13/storage/container_storage_interface/persistent-storage-csi-sc-manage.html) provisioned.
- [Helm](https://helm.sh/docs/intro/install/) v3.9+ is installed.
- [PostgreSQL](https://www.postgresql.org/) database is available with credentials to manage the tablespace (optional).
  - A [reference implementation](https://github.com/parodos-dev/orchestrator-helm-chart#deploying-postgresql-reference-implementation) is provided for your convenience.
- A GitHub API Token - to import items into the catalog, ensure you have a GITHUB_TOKEN with the necessary permissions as detailed [here](https://backstage.io/docs/integrations/github/locations/). For classic token, include the following permissions:
  - repo (all)
  - admin:org (read:org)
  - user (read:user, user:email)

## Installation

### Quick installation
1. Follow instruction [here](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/GitOps.md)
2. Run the following command to set up environment variables:
    ```console
    ./hack/setenv.sh
    ```
  - Accept all default values
  - Provide GH Token (created as describe in prerequisite section)
3. Source the environment variables by running
    ```console
    source .env
    ```
4. Install the orchestrator chart using one of the following options:
   1. **Option 1: Install the chart with SonataFlow services in ephemeral mode for evaluation purposes**
      ```console
      helm install orchestrator orchestrator --set orchestrator.devmode=true \
          --set rhdhOperator.github.token=$GITHUB_TOKEN \
          --set rhdhOperator.k8s.clusterToken=$K8S_CLUSTER_TOKEN --set rhdhOperator.k8s.clusterUrl=$K8S_CLUSTER_URL \
          --set argocd.namespace=$ARGOCD_NAMESPACE --set argocd.url=$ARGOCD_URL --set argocd.username=$ARGOCD_USERNAME \
          --set argocd.password=$ARGOCD_PASSWORD --set argocd.enabled=true --set tekton.enabled=true
      ```
   2. **Option 2: Deploy PostgreSQL reference implementation**
      1. Deploy PostgreSQL reference implementation following these [instructions](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)
      2. Install the orchestrator Helm chart:
        ```console
        helm install orchestrator orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN \
          --set rhdhOperator.k8s.clusterToken=$K8S_CLUSTER_TOKEN --set rhdhOperator.k8s.clusterUrl=$K8S_CLUSTER_URL \
          --set argocd.namespace=$ARGOCD_NAMESPACE --set argocd.url=$ARGOCD_URL --set argocd.username=$ARGOCD_USERNAME \
          --set argocd.password=$ARGOCD_PASSWORD --set argocd.enabled=true --set tekton.enabled=true
        ```
  5. Run the commands prompted at the end of the previous step to wait until the services are ready.

## Detailed Installation

### Additional Prerequisites
In addition to the [prerequisites](https://github.com/parodos-dev/orchestrator-helm-chart#prerequisites) mentioned earlier, is it possible to manually install the following operator:
- `ArgoCD/OpenShift GitOps` operator
  - Ensure at least one instance of `ArgoCD` exists in the designated namespace (referenced by `ARGOCD_NAMESPACE` environment variable).
  - Validated API is `argoproj.io/v1alpha1/AppProject`
- `Tekton/OpenShift Pipelines` operator 
  - Verify it is installed in the orchestrator namespace (e.g. `orchestrator.namespace` release value)
  - Validated APIs are `tekton.dev/v1beta1/Task` and `tekton.dev/v1/Pipeline`

### GitOps environment
See the dedicated [document](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/GitOps.md)

### Deploying PostgreSQL reference implementation
See [here](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

### ArgoCD and workflow namespace
If you manually created the workflow namespaces (e.g., `$WORKFLOW_NAMESPACE`), run this command to add the required label that allows
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
Set value for `$GITHUB_TOKEN` and run:
```console
helm install orchestrator orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN
```

### Install the chart with SonataFlow services in ephemeral mode for evaluation purposes
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
The $K8S_CLUSTER_TOKEN should provide access to resources as detailed [here](https://github.com/janus-idp/backstage-plugins/tree/main/plugins/tekton#prerequisites) and $K8S_CLUSTER_URL from the output of `oc whoami --show-server` (e.g. https://api.cluster-domain:6443).

A sample output:
```console
NAME: orchestrator
LAST DEPLOYED: Fri Mar 29 12:34:59 2024
NAMESPACE: sonataflow-infra
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Helm Release orchestrator installed in namespace sonataflow-infra.

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
Tekton pipeline              YES        orchestrator-gitops
Tekton task                  YES        orchestrator-gitops
ArgoCD project               YES        orchestrator-gitops

====================================================================
Prerequisites check:
The required CRD tekton.dev/v1beta1/Task is already installed.
The required CRD tekton.dev/v1/Pipeline is already installed.
The required CRD argoproj.io/v1alpha1/AppProject is already installed.
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
If a deployment failure occurs for a Custom Resource (CR), check the logs of the pods created by the corresponding job responsible for deploying the failed CR instance.
Note that these jobs are automatically deleted after the deployment of the chart is completed.

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
The [Helm Chart Documentation](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/charts/orchestrator/README.md) is generated by the [frigate tool](https://github.com/rapidsai/frigate). After the tool is installed, you can run the following command to re-generate the chart documentation.
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

The plugins are configured by the `dynamic-plugins-rhdh` configmap in [RHDH operator configuration](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/charts/orchestrator/templates/rhdh-operator.yaml).
To update plugin versions, use the npmjs package name, use the script: [./hack/update_plugins_version.sh](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/hack/update_plugins_version.sh)

## Documentation
See [Helm Chart Documentation](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/charts/orchestrator/README.md) for information about the values used by the helm chart.
