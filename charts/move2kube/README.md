
Move2kube
===========

Helm chart to deploy the move2kube workflow. #magic___^_^___line



## Configuration

The following table lists the configurable parameters of the Move2kube chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `sshSecretName` | name of the secret holding the ssh keys that will be used by move2kube resources | `"sshkeys"` |
| `brokerName` |  | `"default"` |
| `namespace` |  | `"sonataflow-infra"` |
| `workflow.name` |  | `"serverless-workflow-m2k"` |
| `workflow.image` |  | `"quay.io/orchestrator/serverless-workflow-move2kube:latest"` |
| `workflow.brokerURL` |  | `"http://broker-ingress.knative-eventing.svc.cluster.local/sonataflow-infra/default"` |
| `workflow.move2kubeURL` |  | `"https://move2kube-route-sonataflow-infra.apps.cluster-8xfw.redhatworkshops.io"` |
| `workflow.backstageNotificationURL` |  | `"http://orchestrator-backstage.orchestrator/api/notifications/"` |
| `kfunction.name` |  | `"m2k-save-transformation-func"` |
| `kfunction.image` |  | `"quay.io/orchestrator/serverless-workflow-m2k-kfunc:latest"` |
| `instance.name` |  | `"move2kube"` |
| `instance.image` |  | `"quay.io/orchestrator/move2kube-ui:latest"` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._
