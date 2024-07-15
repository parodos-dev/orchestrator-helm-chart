
Orchestrator
===========

Helm chart to deploy the Orchestrator solution suite on OpenShift, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing and Knative Serving.



## Configuration

The following table lists the configurable parameters of the Orchestrator chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `sonataFlowOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `sonataFlowOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless-logic"` |
| `sonataFlowOperator.subscription.channel` | channel of an operator package to subscribe to | `"alpha"` |
| `sonataFlowOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `sonataFlowOperator.subscription.name` | name of the operator package | `"logic-operator-rhel8"` |
| `serverlessOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `serverlessOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless"` |
| `serverlessOperator.subscription.channel` | channel of an operator package to subscribe to | `"stable"` |
| `serverlessOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `serverlessOperator.subscription.name` | name of the operator package | `"serverless-operator"` |
| `rhdhOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `rhdhOperator.github.token` | An authentication token as expected by GitHub. Required for importing resource to the catalog, launching software templates and more. | `""` |
| `rhdhOperator.github.clientId` | The client ID that you generated on GitHub, for GitHub authentication (requires GitHub App). | `""` |
| `rhdhOperator.github.clientSecret` | The client secret tied to the generated client ID. | `""` |
| `rhdhOperator.k8s.clusterToken` | Kubernetes API bearer token used for authentication. | `""` |
| `rhdhOperator.k8s.clusterUrl` | API url of the kubernetes cluster | `""` |
| `rhdhOperator.subscription.namespace` | namespace where the operator should be deployed | `"rhdh-operator"` |
| `rhdhOperator.subscription.channel` | channel of an operator package to subscribe to | `"fast-1.1"` |
| `rhdhOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `rhdhOperator.subscription.name` | name of the operator package | `"rhdh"` |
| `rhdhOperator.subscription.startingCSV` | the starting version for the RHDH operator | `"rhdh-operator.v1.1.2"` |
| `rhdhPlugins.npmRegistry` |  | `"https://npm.registry.redhat.com"` |
| `rhdhPlugins.scope` |  | `"@redhat"` |
| `rhdhPlugins.orchestrator.package` |  | `"backstage-plugin-orchestrator@1.0.0"` |
| `rhdhPlugins.orchestrator.integrity` |  | `"sha512-CuYYR7v2O8EVoI1FA7usidzUPp1N5OOKDkIvhDRPf4I7BxgDCWLqW7rBQ4Z7qBXfpeYJrQOxInc0E2xWEat8JA=="` |
| `rhdhPlugins.orchestrator_backend.package` |  | `"backstage-plugin-orchestrator-backend-dynamic@1.0.0"` |
| `rhdhPlugins.orchestrator_backend.integrity` |  | `"sha512-l0g3T/a1NxX9JogTesZAdUzpNhHQaPxRwki15HWny9GlXCELAx+ta0UC3afsHy6Jp2wOn1prlW0ZuXuc7Ncb0g=="` |
| `rhdhPlugins.notifications.package` |  | `"plugin-notifications@1.0.0"` |
| `rhdhPlugins.notifications.integrity` |  | `"sha512-t+cnwKOfqJJqbgZIMjJ1Hzr1mqHft619QoK5bF7c8TuQGUjQR0NtaIFWUNhR1JFlE4oQz0NDaAgBnDwtjMk9qA=="` |
| `rhdhPlugins.notifications_backend.package` |  | `"plugin-notifications-backend-dynamic@1.0.0"` |
| `rhdhPlugins.notifications_backend.integrity` |  | `"sha512-o4GFXmQu6uUXbCDukXHahZ37sfQQYM92pL3LhkXO5aYKudITKzlv6lEZnb9zO9Rnr3U0LD7ytFzks51EfXssXw=="` |
| `postgres.serviceName` | The name of the Postgres DB service to be used by platform services. Cannot be empty. | `"sonataflow-psql-postgresql"` |
| `postgres.serviceNamespace` | The namespace of the Postgres DB service to be used by platform services. | `"sonataflow-infra"` |
| `postgres.authSecret.name` | name of existing secret to use for PostgreSQL credentials. | `"sonataflow-psql-postgresql"` |
| `postgres.authSecret.userKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-username"` |
| `postgres.authSecret.passwordKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-password"` |
| `postgres.database` | existing database instance used by data index and job service | `"sonataflow"` |
| `orchestrator.namespace` | namespace where the data index, job service and workflows are deployed | `"sonataflow-infra"` |
| `orchestrator.sonataPlatform.resources.requests.memory` |  | `"64Mi"` |
| `orchestrator.sonataPlatform.resources.requests.cpu` |  | `"250m"` |
| `orchestrator.sonataPlatform.resources.limits.memory` |  | `"1Gi"` |
| `orchestrator.sonataPlatform.resources.limits.cpu` |  | `"500m"` |
| `tekton.enabled` | whether to create the Tekton pipeline resources | `false` |
| `argocd.enabled` | whether to install the ArgoCD plugin and create the orchestrator AppProject | `false` |
| `argocd.url` |  | `""` |
| `argocd.namespace` |  | `"orchestrator-gitops"` |
| `argocd.username` |  | `"admin"` |
| `argocd.password` |  | `""` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

