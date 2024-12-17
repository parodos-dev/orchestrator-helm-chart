# Orchestrator Helm Chart

Deploy the Orchestrator solution suite using this Helm chart.\
The chart installs the following components onto the target OpenShift cluster:

- RHDH (Red Hat Developer Hub) Backstage
- OpenShift Serverless Logic Operator (with Data-Index and Job Service)
- OpenShift Serverless Operator
  - Knative Eventing
  - Knative Serving
- (Optional) An ArgoCD project named `orchestrator`. Requires an pre-installed ArgoCD/OpenShift GitOps instance in the cluster. Disabled by default
- (Optional) Tekton tasks and build pipeline. Requires an pre-installed Tekton/OpenShift Pipelines instance in the cluster. Disabled by default

## Important Note for ARM64 Architecture Users

Note that as of November 6, 2023, OpenShift Serverless Operator is based on RHEL 8 images which are not supported on the ARM64 architecture. Consequently, deployment of this helm chart on an [OpenShift Local](https://www.redhat.com/sysadmin/install-openshift-local) cluster on MacBook laptops with M1/M2 chips is not supported.

## Prerequisites

- Logged in to a Red Hat OpenShift Container Platform (version 4.13+) cluster as a cluster administrator.
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) is installed.
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/docs/getting-started/) has been installed in your cluster.
- Your cluster has a [default storage class](https://docs.openshift.com/container-platform/4.13/storage/container_storage_interface/persistent-storage-csi-sc-manage.html) provisioned.
- [Helm](https://helm.sh/docs/intro/install/) v3.9+ is installed.
- A GitHub API Token - to import items into the catalog, ensure you have a `GITHUB_TOKEN` with the necessary permissions as detailed [here](https://backstage.io/docs/integrations/github/locations/).
  -  For classic token, include the following permissions:
      - repo (all)
      - admin:org (read:org)
      - user (read:user, user:email)
      - workflow (all) - required for using the software templates for creating workflows in GitHub
  - For Fine grained token:
      - Repository permissions: **Read** access to metadata, **Read** and **Write** access to actions, actions variables, administration, code, codespaces, commit statuses, environments, issues, pull requests, repository hooks, secrets, security events, and workflows.
      - Organization permissions: **Read** access to members, **Read** and **Write** access to organization administration, organization hooks, organization projects, and organization secrets.


### Deployment with GitOps

  If you plan to deploy in a GitOps environment, make sure you have installed the `ArgoCD/Red Hat OpenShift GitOps` and the `Tekton/Red Hat Openshift Pipelines Install` operators following these [instructions](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/gh-pages/gitops/README.md).
  The Orchestrator installs RHDH and imports software templates designed for bootstrapping workflow development. These templates are crafted to ease the development lifecycle, including a Tekton pipeline to build workflow images and generate workflow K8s custom resources. Furthermore, ArgoCD is utilized to monitor any changes made to the workflow repository and to automatically trigger the Tekton pipelines as needed.

- `ArgoCD/OpenShift GitOps` operator
  - Ensure at least one instance of `ArgoCD` exists in the designated namespace (referenced by `ARGOCD_NAMESPACE` environment variable). Example [here](https://raw.githubusercontent.com/rhdhorchestrator/orchestrator-helm-chart/gh-pages/gitops/resources/argocd-example.yaml)
  - Validated API is `argoproj.io/v1alpha1/AppProject`
- `Tekton/OpenShift Pipelines` operator
  - Validated APIs are `tekton.dev/v1beta1/Task` and `tekton.dev/v1/Pipeline`
  - Requires ArgoCD installed since the manifests are deployed in the same namespace as the ArgoCD instance.

  Remember to enable [argocd](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/145a6cb647253faa1e8d50fcaac75988f5807724/charts/orchestrator/values.yaml#L80) and [tekton](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/145a6cb647253faa1e8d50fcaac75988f5807724/charts/orchestrator/values.yaml#L77) in the `values.yaml` or, alternatively, enabled them via helm's setting flag in the CLI when installing the chart. Example:

  ```console
  helm upgrade -i ... --set argocd.enabled=true --set tekton.enabled=true
  ```

## Installation

1. Install the helm chart using the pre-packaged version

     Add the repository:

     ```bash
     helm repo add orchestrator https://rhdhorchestrator.github.io/orchestrator-helm-chart
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
     orchestrator	https://rhdhorchestrator.github.io/orchestrator-helm-chart
     ```

1. Deploy the PostgreSQL reference implementation for persistence support in SonataFlow following these [instructions](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

1. Create a namespace for the Orchestrator solution:

   ```console
   oc new-project orchestrator
   ```

1. Create a namespace for the Red Hat Developer Hub Operator (RHDH Operator):

   ```console
   oc new-project rhdh-operator
   ```


1.  Download the setup script from the github repository and run it to create the RHDH secret and label the GitOps namespaces:

    ```console
    wget https://raw.githubusercontent.com/rhdhorchestrator/orchestrator-helm-chart/main/hack/setup.sh -O /tmp/setup.sh && chmod u+x /tmp/setup.sh
    ```

    Run the script:
    ```console
    /tmp/setup.sh --use-default
    ```
    **NOTE:** If you don't want to use the default values, omit the `--use-default` and the script will prompt you for input.

    The contents will vary depending on the configuration in the cluster. The following list details all the keys that can appear in the secret:

    > - `BACKEND_SECRET`: Value is randomly generated at script execution. This is the only mandatory key required to be in the secret for the RHDH Operator to start.
    > - `K8S_CLUSTER_URL`: The URL of the Kubernetes cluster is obtained dynamically using `oc whoami --show-server`.
    > - `K8S_CLUSTER_TOKEN`: The value is obtained dynamically based on the provided namespace and service account.
    > - `GITHUB_TOKEN`: This value is prompted from the user during script execution and is not predefined.
    > - `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET`: The value for both these fields are used to authenticate against GitHub. For more information open this [link](https://backstage.io/docs/auth/github/provider/).
    > - `ARGOCD_URL`: This value is dynamically obtained based on the first ArgoCD instance available.
    > - `ARGOCD_USERNAME`: Default value is set to `admin`.
    > - `ARGOCD_PASSWORD`: This value is dynamically obtained based on the first ArgoCD instance available.

    Keys will not be added to the secret if they have no values associated. So for instance, when deploying in a cluster without the GitOps operators, the `ARGOCD_URL`, `ARGOCD_USERNAME` and `ARGOCD_PASSWORD` keys will be omited in the secret.

    Sample of a secret created in a GitOps environment:

    ```console
    $> oc get secret -n rhdh-operator -o yaml backstage-backend-auth-secret
    apiVersion: v1
    data:
      ARGOCD_PASSWORD: ...
      ARGOCD_URL: ...
      ARGOCD_USERNAME: ...
      BACKEND_SECRET: ...
      GITHUB_TOKEN: ...
      K8S_CLUSTER_TOKEN: ...
      K8S_CLUSTER_URL: ...
    kind: Secret
    metadata:
      creationTimestamp: "2024-05-07T22:22:59Z"
      name: backstage-backend-auth-secret
      namespace: rhdh-operator
      resourceVersion: "4402773"
      uid: 2042e741-346e-4f0e-9d15-1b5492bb9916
    type: Opaque
    ```
1.  Install the orchestrator Helm chart:

    ```console
    helm upgrade -i orchestrator orchestrator/orchestrator -n orchestrator
    ```

1.  Run the commands prompted at the end of the previous step to wait until the services are ready.

    Sample output in a GitOps environment:

    ```console
    NAME: orchestrator
    LAST DEPLOYED: Fri Mar 29 12:34:59 2024
    NAMESPACE: orchestrator
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    Helm Release orchestrator installed in namespace orchestrator.

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

    During the installation process, Kubernetes cronjobs are created by the chart to monitor the lifecycle of the CRs managed by the chart: rhdh operator, serverless operator and sonataflow operator. When deleting one of the previously mentioned CRs, a job is triggered that ensures the CR is removed before the operator is.
    In case of any failure at this stage, these jobs remain active, facilitating administrators in retrieving detailed diagnostic information to identify and address the cause of the failure.

    > **Note:** that every minute on the clock a job is triggered to reconcile the CRs with the chart values. These cronjobs are deleted when their respective features (e.g. `rhdhOperator.enabled=false`) are removed or when the chart is removed. This is required because the CRs are not managed by helm due to the CRD dependency pre availability to the deployment of the CR.

### Installing from the git repository for chart development

Use this [guide](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/gh-pages/manual.md) if you plan to develop the helm chart. Note that the requirements for the chart deployment still remain unchanged.

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
    url: 'https://rhdhorchestrator.github.io/orchestrator-helm-chart'
EOF
```

Follow Helm Chart installation instructions [here](https://docs.openshift.com/container-platform/4.15/applications/working_with_helm_charts/configuring-custom-helm-chart-repositories.html)

## Additional information

### Additional Workflow Namespaces

When deploying a workflow in a namespace different from where Sonataflow services are running (e.g., sonataflow-infra), several essential steps must be followed:

1. **Label the Workflow Namespace:**
  To allow Sonataflow services to accept traffic from workflows, apply the following label to the desired workflow namespace:
   ```console
      oc label ns $ADDITIONAL_NAMESPACE rhdh.redhat.com/workflow-namespace=""
   ```
2. **Identify the RHDH Namespace:**
   Retrieve the namespace where RHDH is running by executing:
   ```console
      oc get backstage -A
   ```
   Store the namespace value in RHDH_NAMESPACE.
3. **Identify the Sonataflow Services Namespace:**
   Check the namespace where Sonataflow services are deployed:
   ```console
      oc get sonataflowclusterplatform -A
   ```
   If there is no cluster platform, check for a namespace-specific platform:
   ```console
      oc get sonataflowplatform -A
   ```
   Store the namespace value in SONATAFLOW_PLATFORM_NAMESPACE.

4. **Set Up Network Policy:**
   Configure a network policy to allow traffic only between RHDH, Sonataflow services, and the workflows. The policy can be derived from the charts/orchestrator/templates/network-policy.yaml file:

   ```console
   oc create -f <<EOF
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: allow-rhdh-to-sonataflow-and-workflows
     # Sonataflow and Workflows are using the same namespace.
     namespace: $ADDITIONAL_NAMESPACE
   spec:
     podSelector: {}
     ingress:
       - from:
         - namespaceSelector:
             matchLabels:
               # Allow RHDH namespace to communicate with workflows.
               kubernetes.io/metadata.name: $RHDH_NAMESPACE
         - namespaceSelector:
             matchLabels:
               # Allow Sonataflow services to communicate with workflows.
               kubernetes.io/metadata.name: $SONATAFLOW_PLATFORM_NAMESPACE
   EOF
   ```
5. **Ensure Persistence for the Workflow:**
  If persistence is required, follow these steps:
  * **Create a PostgreSQL Secret:**
    The workflow needs its own schema in PostgreSQL. Create a secret containing the PostgreSQL credentials in the workflow's namespace:
    ```
    oc get secret sonataflow-psql-postgresql -n sonataflow-infra -o yaml > secret.yaml
    sed -i '/namespace: sonataflow-infra/d' secret.yaml
    oc apply -f secret.yaml -n $ADDITIONAL_NAMESPACE
    ```
  * **Configure the Namespace Attribute:**
    Add the namespace attribute under the `serviceRef` property where the PostgreSQL server is deployed.
    ```yaml
    apiVersion: sonataflow.org/v1alpha08
    kind: SonataFlow
      ...
    spec:
      ...
      persistence:
        postgresql:
          secretRef:
            name: sonataflow-psql-postgresql
            passwordKey: postgres-password
            userKey: postgres-username
          serviceRef:
            databaseName: sonataflow
            databaseSchema: greeting
            name: sonataflow-psql-postgresql
            namespace: $POSTGRESQL_NAMESPACE
            port: 5432
    ```
    Replace POSTGRESQL_NAMESPACE with the namespace where the PostgreSQL server is deployed.

By following these steps, the workflow will have the necessary credentials to access PostgreSQL and will correctly reference the service in a different namespace.

### GitOps environment

See the dedicated [document](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/gh-pages/gitops/README.md)

### Deploying PostgreSQL reference implementation

See [here](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

### ArgoCD and workflow namespace

If you manually created the workflow namespaces (e.g., `$WORKFLOW_NAMESPACE`), run this command to add the required label that allows ArgoCD deploying instances there:

```console
oc label ns $WORKFLOW_NAMESPACE argocd.argoproj.io/managed-by=$ARGOCD_NAMESPACE
```

### Workflow installation

Follow [Workflows Installation](https://www.rhdhorchestrator.io/serverless-workflows-config/)

## Cleanup

**\/!\\ Before removing the orchestrator, make sure you first removed installed workflows. Otherwise the deletion may hung in termination state**

To remove the installation from the cluster, run:

```console
helm delete orchestrator
release "orchestrator" uninstalled
```

Note that the CRDs created during the installation process will remain in the cluster.

To clean the rest of the resources, run:
```console
oc get crd -o name | grep -e sonataflow -e rhdh | xargs oc delete
oc delete namespace orchestrator sonataflow-infra rhdh-operator
```

If you want to remove *knative* related resources, you may also run:
```console
oc get crd -o name | grep -e knative | xargs oc delete
```


## Troubleshooting

### Timeout or errors during `oc wait` commands

If you encounter errors or timeouts while executing `oc wait` commands, follow these steps to troubleshoot and resolve the issue:

1. **Check Deployment Status**: Review the output of the `oc wait` commands to identify which deployments met the condition and which ones encountered errors or timeouts.
   For example, if you see `error: timed out waiting for the condition on deployments/sonataflow-platform-data-index-service`, investigate further using `oc describe deployment sonataflow-platform-data-index-service -n sonataflow-infra` and `oc logs sonataflow-platform-data-index-service -n sonataflow-infra `
