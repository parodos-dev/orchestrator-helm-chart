# Orchestrator-k8s helm chart 

This chart will install the Orchestrator and all its dependencies on kubernetes. 

**THIS CHART IS NOT SUITED FOR PRODUCTION PURPOSES**, you should only use it for development or tests purposes

The chart deploys:
- RHDH-backstage https://github.com/redhat-developer/rhdh-chart
- Serverless Workflows Operator (see sonata-serverless-operator.yaml)
- knative serving
- Knative eventing
- Serverless Workflows (optional)

### Usage

```console
helm repo add orchestrator https://rhdhorchestrator.github.io/orchestrator-helm-chart

helm install orchestrator orchestrator/orchestrator-k8s
```

## Configuration
All of the backstage app-config is derived from the values.yaml.

### Secrets as env vars:
To use secret as env vars, like the one used for the notification, see charts/Orchestrator-k8s/templates/secret.yaml
Every key in that secret will be available in the app-config for resolution.


## Development
```console
git clone https://github.com/rhdhorchestrator.github.io/orchestrator-helm-chart
cd orchestrator-helm-chart/charts/orchestrator-k8s


helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add backstage https://backstage.github.io/charts
helm repo add postgresql-persistent https://sclorg.github.io/helm-charts
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart
helm repo add workflows https://rhdhorchestrator.io/serverless-workflows-config

helm dependencies build
helm install orchestrator .
```


The output should look like that
```console
$ helm install orchestrator .
Release "orchestrator" has been upgraded. Happy Helming!
NAME: orchestrator
LAST DEPLOYED: Tue Sep 19 18:19:07 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
This chart will install RHDH-backstage(RHDH upstream) + Serverless Workflows.

To get RHDH's route location:
    $ oc get route orchestrator-white-backstage -o jsonpath='https://{ .spec.host }{"\n"}'

To get the serverless workflow operator status:
    $ oc get deploy -n sonataflow-operator-system 

To get the serverless workflows status:
    $ oc get sf

```

The chart notes will provide more information on:
  - route location of backstage
  - the sonata operator status
  - the sonata workflow deployed status
