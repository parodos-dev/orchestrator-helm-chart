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

## Installation

1. Get the Helm chart from one of the following options

   - **Pre-Packaged Helm Chart**\
     If you choose to install the Helm chart from the Helm repository, you'll be leveraging the pre-packaged version provided by the chart maintainer. This method is convenient and ensures that you're using a stable, tested version of the chart.
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

   - **Manual Chart Deployment**\
      By cloning the repository and navigating to the charts directory, you'll have access to the raw chart files and can customize them to fit your specific requirements.
     ```console
     git clone git@github.com:parodos-dev/orchestrator-helm-chart.git
     cd orchestrator-helm-chart/charts
     ```

2. Create a namespace for the Orchestrator solution:

   ```console
   oc new-project orchestrator
   ```

3. Set GITHUB_TOKEN environment variable

   ```console
   export GITHUB_TOKEN=<github token>
   ```

4. Deploy PostgreSQL reference implementation following these [instructions](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

### ...without GitOps

1.  Install the orchestrator Helm chart:

    ```console
    helm upgrade -i orchestrator orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN
    ```

2.  Run the commands prompted at the end of the previous step to wait until the services are ready.

### ... with GitOps

1.  Install `Red Hat OpenShift Pipelines` and `Red Hat OpenShift GitOps` operators following these [instructions](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/gitops/README.md).
    The Orchestrator installs RHDH and imports software templates designed for bootstrapping workflow development. These templates are crafted to ease the development lifecycle, including a Tekton pipeline to build workflow images and generate workflow K8s custom resources. Furthermore, ArgoCD is utilized to monitor any changes made to the workflow repository and to automatically trigger the Tekton pipelines as needed. This installation process ensures that all necessary Tekton and ArgoCD resources are provisioned within the same cluster.

2.  Run the following command to set up environment variables:

    ```console
    ./hack/setenv.sh --use-default
    ```

    This script generates a `.env` file that contains all the calculated environment variables.

    > **NOTE:** If you don't want to use the default values, omit the `--use-default` and the script will prompt you for input.
    >
    > Default values are calculated as follows:
    >
    > - `WORKFLOW_NAMESPACE`: Default value is set to `sonataflow-infra`.
    > - `K8S_CLUSTER_URL`: The URL of the Kubernetes cluster is obtained dynamically using `oc whoami --show-server`.
    > - `K8S_CLUSTER_TOKEN`: The value is obtained dynamically based on the provided namespace and service account.
    > - `GITHUB_TOKEN`: This value is prompted from the user during script execution and is not predefined.
    > - `ARGOCD_NAMESPACE`: Default value is set to `orchestrator-gitops`.
    > - `ARGOCD_URL`: This value is dynamically obtained based on the first ArgoCD instance available.
    > - `ARGOCD_USERNAME`: Default value is set to `admin`.
    > - `ARGOCD_PASSWORD`: This value is dynamically obtained based on the first ArgoCD instance available.

3.  Install the orchestrator Helm chart:

    ```console
    helm upgrade -i orchestrator orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN \
    --set rhdhOperator.k8s.clusterToken=$K8S_CLUSTER_TOKEN --set rhdhOperator.k8s.clusterUrl=$K8S_CLUSTER_URL \
    --set argocd.namespace=$ARGOCD_NAMESPACE --set argocd.url=$ARGOCD_URL --set argocd.username=$ARGOCD_USERNAME \
    --set argocd.password=$ARGOCD_PASSWORD --set argocd.enabled=true --set tekton.enabled=true
    ```

4.  Run the commands prompted at the end of the previous step to wait until the services are ready.

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

### Additional Workflow Namespaces

If you want to deploy workflows on other namespaces, make sure you follow these steps:

 - For the cluster Sonataflow services to accept the traffic from the workflows, set this label:
   ```console
      oc label ns my-additional-workflow-ns rhdh.redhat.com/workflow-namespace=""
   ```

 - Set a network policy to allow only RHDH and Sonatflow services traffic. Taken from the `charts/orchestrator/templates/network-policy.yaml`

   ```console
      oc create -f <<EOF
      apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      metadata:
        name: allow-rhdh-to-sonataflow-and-workflows
        # Sonataflow and Workflows are using the same namespace.
        namespace: my-additional-workflow-ns
      spec:
        podSelector: {}
        ingress:
          - from:
            - namespaceSelector:
                matchLabels:
                  # Allow RHDH namespace to communicate with workflows and sonataflow services, see the chart for the default value
                  kubernetes.io/metadata.name: rhdh-operator
            - namespaceSelector:
                matchLabels:
                  # Allow any other namespace the has workflows deployed because this is where
                  # this namespace contains the sonataflow services
                  rhdh.redhat.com/workflow-namespace: ""
      EOF
   ```

### GitOps environment

See the dedicated [document](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/GitOps.md)

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
oc get crd -o name | grep -e sonataflow -e rhdh | xargs oc delete
oc delete namespace orchestrator
```

## Troubleshooting

### Timeout or errors during `oc wait` commands

If you encounter errors or timeouts while executing `oc wait` commands, follow these steps to troubleshoot and resolve the issue:

1. **Check Deployment Status**: Review the output of the `oc wait` commands to identify which deployments met the condition and which ones encountered errors or timeouts.
   For example, if you see `error: timed out waiting for the condition on deployments/sonataflow-platform-data-index-service`, investigate further using `oc describe deployment sonataflow-platform-data-index-service -n sonataflow-infra` and `oc logs sonataflow-platform-data-index-service -n sonataflow-infra `
