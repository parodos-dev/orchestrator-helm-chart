Move2kube
===========

# Installation
From `charts` folder run 
```console
helm install move2kube move2kube
```

Then update `move2kube_url` in [values file](values.yaml) with the route of the move2kube instance:
```console
$ oc -n sonataflow-infra get routes move2kube-route 

move2kube-route   move2kube-route-sonataflow-infra.apps.cluster-8xfw6.dynamic.redhatworkshops.io          move2kube-svc   <all>   edge          None

```

Once updated run 
```console
helm upgrade move2kube move2kube && oc -n sonataflow-infra scale deployment serverless-workflow-m2k --replicas=0 && oc -n sonataflow-infra scale deployment serverless-workflow-m2k --replicas=1
```