# Orchestrator-k8s helm chart 

This chart will install the Orchestrator and all its dependencies on kubernetes. 
It is well suited for dev/QE/test or resource-constrained environments.

The chart deploys:
- Janus-IDP
- Serverless Workflows Operator (see sonata-serverless-operator.yaml)
- knative serving
- Knative eventing
- Serverless Workflows (optional)

### Usage

```console
helm repo add orchestrator https://parodos-dev.github.io/orchestrator-helm-chart

helm install orchestrator orchestrator-k8s
```


## Development
```console
git clone https://github.com/parodos-dev.github.io/orchestrator-helm-chart
cd orchestrator-helm-chart/charts/orchestrator-k8s

helm dependencies build
helm install orchestrator . -f values.yaml 
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
This chart will install Janus-IDP + Serverless Workflows.

It is under development and meant for non-prod environment for now

To get Jauns-IDP's route location:
    $ oc get route orchestrator-white-backstage -o jsonpath='https://{ .spec.host }{"\n"}'

To get the serverless workflow operator status:
    $ oc get deploy -n sonataflow-operator-system 

To get the serverless workflow status:
    $ oc get sf starter 

```

The chart notes will provide more information on:
  - route location of backstage
  - the sonata operator status
  - the sonata workflow deployed status
