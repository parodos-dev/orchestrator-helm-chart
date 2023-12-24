
Orchestrator
===========

Helm chart to deploy the Orchestrator solution suite on OpenShift, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator,  Knative Eventing, Knative Serving, Data Index and Job Service.



## Configuration

The following table lists the configurable parameters of the Orchestrator chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `includeCustomResources` | set to true to have the custom resources (KnativeEventing, KnativeServing, SonataFlow and SonataFlowPlatform). | `false` |
| `sonataFlowOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `sonataFlowOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-operators"` |
| `sonataFlowOperator.subscription.channel` | channel of an operator package to subscribe to | `"alpha"` |
| `sonataFlowOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `sonataFlowOperator.subscription.pkgName` | name of the operator package | `"sonataflow-operator"` |
| `sonataFlowOperator.subscription.sourceImage` | catalog image of the development build. Unset it for the release build. | `"quay.io/jianrzha/kogito-serverless-operator-catalog:v2.0.0"` |
| `sonataFlowOperator.subscription.sourceNamespace` | namespace of the catalog source | `"openshift-marketplace"` |
| `sonataFlowOperator.subscription.source` | name of the catalog source for the operator | `"sonataflow-operator"` |
| `serverlessOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `serverlessOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless"` |
| `serverlessOperator.subscription.channel` | channel of an operator package to subscribe to | `"stable"` |
| `serverlessOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `serverlessOperator.subscription.pkgName` | name of the operator package | `"serverless-operator"` |
| `serverlessOperator.subscription.sourceNamespace` | namespace of the catalog source | `"openshift-marketplace"` |
| `postgres.postgresDBHostAndPort` | host and port URL of an existing Postgres DB used by dataindex and job service | `"sonataflow-psql-postgresql.sonataflow-infra.svc.cluster.local:5432"` |
| `postgres.authSecret.name` | name of existing secret to use for PostgreSQL credentials. | `"sonataflow-psql-postgresql"` |
| `postgres.authSecret.passwordKey` | name of key in existing secret to use for PostgreSQL credentials | `"postgres-password"` |
| `postgres.database` | database instance used by data index and job service | `"sonataflow"` |
| `postgres.username` | database user name | `"postgres"` |
| `backstage.upstream.backstage.image.tag` | Hack to bypass bug in 'next' tag | `pr-814` |
| `backstage.upstream.backstage.appConfig.orchestrator.catalog.environment` |  | `"development"` |
| `orchestrator.namespace` | namespace where the data index, job service and workflows are deployed | `"sonataflow-infra"` |
| `orchestrator.dataindex.image` | image for data index | `"quay.io/kiegroup/kogito-data-index-postgresql:1.42"` |
| `orchestrator.dataindex.name` | service name of the data index | `"data-index-service"` |
| `orchestrator.dataindex.port` | service port of the data index | `8080` |
| `orchestrator.jobsservice.image` | image for job service | `"quay.io/kiegroup/kogito-jobs-service-postgresql:1.44"` |
| `orchestrator.jobsservice.name` | service name of the job service | `"jobs-service-service"` |
| `orchestrator.jobsservice.port` | service port of the job service | `8080` |
| `orchestrator.sonataPlatform.resources.requests.memory` |  | `"64Mi"` |
| `orchestrator.sonataPlatform.resources.requests.cpu` |  | `"250m"` |
| `orchestrator.sonataPlatform.resources.limits.memory` |  | `"1Gi"` |
| `orchestrator.sonataPlatform.resources.limits.cpu` |  | `"500m"` |
| `orchestrator.sonataflows` | workflows to get deployed | `[{"name": "event-timeout", "description": "Event timeout example on k8s!", "version": "0.0.1", "profile": "prod", "serviceTargetPort": 8080, "propsConfigData": "application.properties: |\n  # Data Index configuration\n  mp.messaging.outgoing.kogito-processinstances-events.url=http://data-index-service/processes\n  mp.messaging.outgoing.kogito-usertaskinstances-events.url=http://data-index-service/tasks\n  mp.messaging.outgoing.kogito-variables-events.url=http://data-index-service/variables\n  # Skip user tasks and variables events sending.\n  kogito.events.usertasks.enabled=false\n  kogito.events.variables.enabled=false\n  quarkus.log.category.\"io.smallrye.reactive.messaging\".level = DEBUG\n  quarkus.log.category.\"org.kie\".level = DEBUG\n  quarkus.log.category.\"io.quarkus.reactivemessaging\".level = DEBUG\n  quarkus.log.category.\"io.vertx\".level = DEBUG\n", "spec": "flow:\n  start: PrintStartMessage\n  events:\n    - name: event1\n      source: ''\n      type: event1_event_type\n    - name: event2\n      source: ''\n      type: event2_event_type\n  functions:\n    - name: systemOut\n      type: custom\n      operation: sysout\n  timeouts:\n    eventTimeout: PT60S\n  states:\n    - name: PrintStartMessage\n      type: operation\n      actions:\n        - name: printSystemOut\n          functionRef:\n            refName: systemOut\n            arguments:\n              message: \"${\\\"event-state-timeouts: \\\" + $WORKFLOW.instanceId + \\\" has started.\\\"}\"\n      transition: WaitForEvent1\n    - name: WaitForEvent1\n      type: event\n      onEvents:\n        - eventRefs: [ event1 ]\n          eventDataFilter:\n            data: \"${ \\\"The event1 was received.\\\" }\"\n            toStateData: \"${ .exitMessage1 }\"\n          actions:\n            - name: printAfterEvent1\n              functionRef:\n                refName: systemOut\n                arguments:\n                  message: \"${\\\"event-state-timeouts: \\\" + $WORKFLOW.instanceId + \\\" executing actions for event1.\\\"}\"\n\n      transition: WaitForEvent2\n    - name: WaitForEvent2\n      type: event\n      onEvents:\n        - eventRefs: [ event2 ]\n          eventDataFilter:\n            data: \"${ \\\"The event2 was received.\\\" }\"\n            toStateData: \"${ .exitMessage2 }\"\n          actions:\n            - name: printAfterEvent2\n              functionRef:\n                refName: systemOut\n                arguments:\n                  message: \"${\\\"event-state-timeouts: \\\" + $WORKFLOW.instanceId + \\\" executing actions for event2.\\\"}\"\n      transition: PrintExitMessage\n    - name: PrintExitMessage\n      type: operation\n      actions:\n        - name: printSystemOut\n          functionRef:\n            refName: systemOut\n            arguments:\n              message: \"${\\\"event-state-timeouts: \\\" + $WORKFLOW.instanceId + \\\" has finalized. \\\" + if .exitMessage1 != null then .exitMessage1 else \\\"The event state did not receive event1, and the timeout has overdue\\\" end + \\\" -- \\\" + if .exitMessage2 != null then .exitMessage2 else \\\"The event state did not receive event2, and the timeout has overdue\\\" end }\"\n      end: true"}]` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

