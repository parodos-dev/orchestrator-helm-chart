
Orchestrator
===========

Helm chart to deploy the Orchestrator solution suite on OpenShift, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing and Knative Serving. #magic___^_^___line



## Configuration

The following table lists the configurable parameters of the Orchestrator chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `sonataFlowOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `sonataFlowOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-operators"` |
| `sonataFlowOperator.subscription.channel` | channel of an operator package to subscribe to | `"alpha"` |
| `sonataFlowOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `sonataFlowOperator.subscription.pkgName` | name of the operator package | `"sonataflow-operator"` |
| `sonataFlowOperator.subscription.sourceImage` | catalog image of the development build. Unset it for the release build. | `"quay.io/masayag/kogito-serverless-operator-catalog:v2.0.0-snapshot"` |
| `sonataFlowOperator.subscription.sourceNamespace` | namespace of the catalog source | `"openshift-marketplace"` |
| `sonataFlowOperator.subscription.source` | name of the catalog source for the operator | `"sonataflow-operator"` |
| `serverlessOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `serverlessOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless"` |
| `serverlessOperator.subscription.channel` | channel of an operator package to subscribe to | `"stable"` |
| `serverlessOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `serverlessOperator.subscription.pkgName` | name of the operator package | `"serverless-operator"` |
| `serverlessOperator.subscription.sourceNamespace` | namespace of the catalog source | `"openshift-marketplace"` |
| `postgres.serviceName` | The name of the Postgres DB service to be used by dataindex and job service. Cannot be empty. | `"sonataflow-psql-postgresql"` |
| `postgres.serviceNamespace` | The namespace of the Postgres DB service to be used by dataindex and job service. | `"sonataflow-infra"` |
| `postgres.authSecret.name` | name of existing secret to use for PostgreSQL credentials. | `"sonataflow-psql-postgresql"` |
| `postgres.authSecret.userKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-username"` |
| `postgres.authSecret.passwordKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-password"` |
| `postgres.database` | existing database instance used by data index and job service | `"sonataflow"` |
| `backstage.global.dynamic.includes` |  | `["dynamic-plugins.default.yaml"]` |
| `backstage.global.dynamic.plugins` |  | `[{"disabled": false, "integrity": "sha512-iVywjs0wOSgTFRV0n9k70+vkl92JF6jJaemqkIrooZAix1v8MiklsQe83bRrcASOh6SnQDbTIils+FHAWjV+qQ==", "package": "@janus-idp/backstage-plugin-orchestrator-backend-dynamic@1.0.2", "pluginConfig": {"orchestrator": {"dataIndexService": {"url": "http://sonataflow-platform-data-index-service.sonataflow-infra"}, "editor": {"path": "https://sandbox.kie.org/swf-chrome-extension/0.32.0"}}}}, {"disabled": false, "integrity": "sha512-Lmma6or08EnlM5va95VSz/P9sVbXZTA95kHs9JHjaZfdbcEj7J2oTjYXdKG+fd4yfVdl0tD7/QP9cfYCY98UIg==", "package": "@janus-idp/backstage-plugin-orchestrator@1.1.1", "pluginConfig": {"dynamicPlugins": {"frontend": {"janus-idp.backstage-plugin-orchestrator": {"appIcons": [{"importName": "OrchestratorIcon", "module": "OrchestratorPlugin", "name": "orchestratorIcon"}], "dynamicRoutes": [{"importName": "OrchestratorPage", "menuItem": {"icon": "orchestratorIcon", "text": "Orchestrator"}, "module": "OrchestratorPlugin", "path": "/orchestrator"}]}}}}}]` |
| `backstage.upstream.backstage.image.tag` |  | `"next"` |
| `backstage.upstream.backstage.appConfig.integrations.github` |  | `[{"host": "github.com", "token": "INSERT VALID TOKEN HERE"}]` |
| `backstage.upstream.backstage.appConfig.auth.environment` |  | `"development"` |
| `backstage.upstream.backstage.appConfig.auth.providers.github.development.clientId` |  | `"INSERT VALID CLIENT ID HERE"` |
| `backstage.upstream.backstage.appConfig.auth.providers.github.development.clientSecret` |  | `"INSERT VALID CLIENT SECRET HERE"` |
| `backstage.upstream.backstage.appConfig.catalog.rules` |  | `[{"allow": ["Component", "System", "Group", "Resource", "Location", "Template", "API", "User", "Domain"]}]` |
| `backstage.upstream.backstage.appConfig.catalog.locations` |  | `[{"type": "url", "target": "https://github.com/janus-idp/backstage-plugins/blob/main/plugins/notifications-backend/users.yaml"}, {"type": "url", "target": "https://github.com/parodos-dev/workflow-software-templates/blob/main/entities/workflow-resources.yaml"}, {"type": "url", "target": "https://github.com/parodos-dev/workflow-software-templates/blob/main/template/template.yaml"}, {"type": "url", "target": "https://github.com/janus-idp/software-templates/blob/main/showcase-templates.yaml"}]` |
| `backstage.upstream.backstage.appConfig.backend.csp.frame-src` |  | `["https://sandbox.kie.org"]` |
| `backstage.upstream.backstage.appConfig.backend.database.client` |  | `"pg"` |
| `backstage.upstream.backstage.appConfig.backend.database.connection.password` |  | `"${POSTGRESQL_ADMIN_PASSWORD}"` |
| `backstage.upstream.backstage.appConfig.backend.database.connection.user` |  | `"postgres"` |
| `backstage.upstream.backstage.appConfig.backend.database.connection.host` |  | `"orchestrator-postgresql-hl.orchestrator.svc.cluster.local"` |
| `backstage.upstream.backstage.appConfig.backend.database.connection.port` |  | `5432` |
| `orchestrator.devmode` | devmode runs sonataflow services in ephemeral mode (for a non-production use) | `false` |
| `orchestrator.namespace` | namespace where the data index, job service and workflows are deployed | `"sonataflow-infra"` |
| `orchestrator.sonataPlatform.resources.requests.memory` |  | `"64Mi"` |
| `orchestrator.sonataPlatform.resources.requests.cpu` |  | `"250m"` |
| `orchestrator.sonataPlatform.resources.limits.memory` |  | `"1Gi"` |
| `orchestrator.sonataPlatform.resources.limits.cpu` |  | `"500m"` |
| `orchestrator.sonataPlatform.dataIndex.image` | To be removed when stable version is released | `"quay.io/kiegroup/kogito-data-index-postgresql-nightly:latest"` |
| `orchestrator.sonataPlatform.jobService.image` | To be removed when stable version is released | `"quay.io/kiegroup/kogito-jobs-service-postgresql-nightly:latest"` |
| `orchestrator.sonataflows` | workflows to get deployed - this option will be removed once the plugin will interact directly with the data-index | `[{"name": "greeting", "image": "quay.io/orchestrator/serverless-workflow-greeting:latest"}]` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

