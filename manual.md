# Local installation for chart development

# Installation\
The following document describes the steps for installing the helm chart for local development. When deploying in such environment, the expectation is that the user will make changes to the chart and thus, the repository needs to be cloned locally for implementing the changes.

1. Clone the git repository

    ```console
    git clone git@github.com:parodos-dev/orchestrator-helm-chart.git
    cd orchestrator-helm-chart/charts
    ```

2. Create the following objects following the instructions on the main page\
  The orchestrator requires to have al least the following deployed in the cluster to work:
  - `rhdh-operator` namespace
  - `backstage-backend-auth-secret` secret in the `rhdh-operator` namespace with at least the `BACKEND_SECRET` key with a random value. If you plan to develop with GitOps integration, run the `hack/setup.sh` script to automate the creation of the secret
  - `sonataflow-infra` namespace
  - `postgreSQL` instance deployed in the `sonataflow-infra` namespace following these [instructions](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/postgresql/README.md)

3. Configure the `values.yaml` fields\
    Before installing the chart, edit the `values.yaml` file and set the values accordingly. Remember to set to `true` the `argocd.enabled` and `tekton.enabled` fields when installing against a GitOps environment.

    ```console
    helm upgrade -i orchestrator orchestrator -n orchestrator
    ```

10.  Run the commands prompted at the end of the previous step to wait until the services are ready.

    Sample output in a GitOps environment:

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
    ```

During the installation process, Kubernetes jobs are created by the chart to monitor the installation progress and wait for the CRDs to be fully deployed by the operators. In case of any failure at this stage, these jobs remain active, facilitating administrators in retrieving detailed diagnostic information to identify and address the cause of the failure.

> **Note:** that these jobs are automatically deleted after the deployment of the chart is completed.

# Cleanup

To remove the installation from the cluster, run:

```console
helm delete orchestrator
oc delete project orchestrator rhdh-operator sonataflow-infra
```

Note that the CRDs created during the installation process will remain in the cluster.
To clean the rest of the resources, run:

```console
oc get crd -o name | grep -e sonataflow -e rhdh -e knative | xargs oc delete
```

## Troubleshooting

### Timeout or errors during `oc wait` commands

If you encounter errors or timeouts while executing `oc wait` commands, follow these steps to troubleshoot and resolve the issue:

1. **Check Deployment Status**: Review the output of the `oc wait` commands to identify which deployments met the condition and which ones encountered errors or timeouts.
   For example, if you see `error: timed out waiting for the condition on deployments/sonataflow-platform-data-index-service`, investigate further using `oc describe deployment sonataflow-platform-data-index-service -n sonataflow-infra` and `oc logs sonataflow-platform-data-index-service -n sonataflow-infra `
