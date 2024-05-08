# Orchestrator Helm Chart

Deploy the Orchestrator solution suite using this Helm chart.\
The chart installs the following components onto the target OpenShift cluster:

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
  - A [reference implementation](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md) is provided for your convenience.
- A GitHub API Token - to import items into the catalog, ensure you have a `GITHUB_TOKEN` with the necessary permissions as detailed [here](https://backstage.io/docs/integrations/github/locations/). For classic token, include the following permissions:
  - repo (all)
  - admin:org (read:org)
  - user (read:user, user:email)

### Optional (GitOps operators)
  If you plan to deploy in a GitOps environment, make sure you have installed the `ArgoCD/Red Hat OpenShift GitOps` and the `Tekton/Red Hat Openshift Pipelines Install` operators following these [instructions](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/gitops/README.md).
  The Orchestrator installs RHDH and imports software templates designed for bootstrapping workflow development. These templates are crafted to ease the development lifecycle, including a Tekton pipeline to build workflow images and generate workflow K8s custom resources. Furthermore, ArgoCD is utilized to monitor any changes made to the workflow repository and to automatically trigger the Tekton pipelines as needed. This installation process ensures that all necessary Tekton and ArgoCD resources are provisioned within the same cluster.

## Installation

1. Install the helm chart using the pre-packaged version

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

1. Deploy the PostgreSQL reference implementation for persistence support in SonataFlow following these [instructions](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

1. Create a namespace for the Orchestrator solution:

   ```console
   oc new-project orchestrator
   ```

1. Create a namespace for the Red Hat Developer Hub Operator (RHDH Operator):

   ```console
   oc new-project rhdh-operator
   ```


1.  Run the following command to set up environment variables:

    ```console
    ./hack/setup.sh --use-default
    ```

    This script creates a secret in the `rhdh-operator` namespace required for Backstage to authenticate against Kubernetes, GitHub and ArgoCD, and also labels the namespaces where workflows run and the ArgoCD instance for the Orchestrator exists, so that the helm chart can identify them when installing/upgrading and deploy the related manifests in the correct namespaces.

    > **NOTE:** If you don't want to use the default values, omit the `--use-default` and the script will prompt you for input.
    >
    > Default values are calculated as follows:
    >
    > - `WORKFLOW_NAMESPACE`: Default value is set to `sonataflow-infra`.
    > - `K8S_CLUSTER_URL`: The URL of the Kubernetes cluster is obtained dynamically using `oc whoami --show-server`.
    > - `K8S_CLUSTER_TOKEN`: The value is obtained dynamically based on the provided namespace and service account.
    > - `GITHUB_TOKEN`: This value is prompted from the user during script execution and is not predefined. Empty if none is available.
    > - `ARGOCD_NAMESPACE`: Default value is set to `orchestrator-gitops`. The script validates that there is an ArgoCD instance running in the given namespace, empty if none is available.
    > - `ARGOCD_URL`: This value is dynamically obtained based on the first ArgoCD instance available. Empty if none is available.
    > - `ARGOCD_USERNAME`: Default value is set to `admin`.
    > - `ARGOCD_PASSWORD`: This value is dynamically obtained based on the first ArgoCD instance available. Empty if none is available.

1.  Install the orchestrator Helm chart:

    ```console
    helm upgrade -i orchestrator orchestrator/orchestrator --set argocd.enabled=true --set tekton.enabled=true -n orchestrator
    ```

1.  Run the commands prompted at the end of the previous step to wait until the services are ready.

    Sample output:

    ````console
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
    ```console
      oc wait -n openshift-serverless deploy/knative-openshift --for=condition=Available --timeout=5m
      oc wait -n knative-eventing knativeeventing/knative-eventing --for=condition=Ready --timeout=5m
      oc wait -n knative-serving knativeserving/knative-serving --for=condition=Ready --timeout=5m
      oc wait -n openshift-serverless-logic deploy/logic-operator-rhel8-controller-manager --for=condition=Available --timeout=5m
      oc wait -n sonataflow-infra sonataflowplatform/sonataflow-platform --for=condition=Succeed --timeout=5m
      oc wait -n sonataflow-infra deploy/sonataflow-platform-data-index-service --for=condition=Available --timeout=5m
      oc wait -n sonataflow-infra deploy/sonataflow-platform-jobs-service --for=condition=Available --timeout=5m
      oc wait -n rhdh-operator backstage backstage --for=condition=Deployed=True
      oc wait -n rhdh-operator deploy/backstage-backstage --for=condition=Available --timeout=5m
    ````

During the installation process, Kubernetes jobs are created by the chart to monitor the installation progress and wait for the CRDs to be fully deployed by the operators. In case of any failure at this stage, these jobs remain active, facilitating administrators in retrieving detailed diagnostic information to identify and address the cause of the failure.

> **Note:** that these jobs are automatically deleted after the deployment of the chart is completed.

### Installing from the git repository for chart development

Use this [guide](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/manual.md) if you plan to develop the helm chart. Note that the requirements for the chart deployment still remain unchanged.

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

## Additional information

### Prerequisites

In addition to the [prerequisites](https://github.com/parodos-dev/orchestrator-helm-chart#prerequisites) mentioned earlier, it is possible to manually install the following operator:

- `ArgoCD/OpenShift GitOps` operator
  - Ensure at least one instance of `ArgoCD` exists in the designated namespace (referenced by `ARGOCD_NAMESPACE` environment variable).
  - Validated API is `argoproj.io/v1alpha1/AppProject`
- `Tekton/OpenShift Pipelines` operator
  - Validated APIs are `tekton.dev/v1beta1/Task` and `tekton.dev/v1/Pipeline`

### GitOps environment

See the dedicated [document](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/gitops/README.md)

### Deploying PostgreSQL reference implementation

See [here](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

### ArgoCD and workflow namespace

If you manually created the workflow namespaces (e.g., `$WORKFLOW_NAMESPACE`), run this command to add the required label that allows ArgoCD deploying instances there:

```console
oc label ns $WORKFLOW_NAMESPACE argocd.argoproj.io/managed-by=$ARGOCD_NAMESPACE
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
oc get crd -o name | grep -e sonataflow -e rhdh -e knative | xargs oc delete
oc delete namespace orchestrator sonataflow-infra rhdh-operator
```

## Troubleshooting

### Timeout or errors during `oc wait` commands

If you encounter errors or timeouts while executing `oc wait` commands, follow these steps to troubleshoot and resolve the issue:

1. **Check Deployment Status**: Review the output of the `oc wait` commands to identify which deployments met the condition and which ones encountered errors or timeouts.
   For example, if you see `error: timed out waiting for the condition on deployments/sonataflow-platform-data-index-service`, investigate further using `oc describe deployment sonataflow-platform-data-index-service -n sonataflow-infra` and `oc logs sonataflow-platform-data-index-service -n sonataflow-infra `
