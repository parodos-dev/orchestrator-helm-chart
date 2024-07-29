In an RHDH installation, there are two primary ConfigMaps that require modification, typically found under the *rhdh-operator* namespaces:

* *dynamic-plugins* ConfigMap: This ConfigMap houses the configuration for enabling and configuring dynamic plugins. To incorporate the orchestrator plugins, append the following configuration to the *dynamic-plugins* ConfigMap:

```yaml
    plugins:
      - disabled: false
        package: "@janus-idp/backstage-plugin-orchestrator-backend-dynamic@1.8.0"
        integrity: sha512-wVZE7Dak10edxh1ZEckzYKrE13GrqhzSVelURhxjZcgXEHdGPWYUFHNMEpte7hzIBE85350Ka7fpy7C4BNPvEw==
        pluginConfig:
          orchestrator:
            dataIndexService:
              url: http://sonataflow-platform-data-index-service.sonataflow-infra
      - disabled: false
        package: "@janus-idp/backstage-plugin-orchestrator@1.10.6"
        integrity: sha512-qSXQ2O7/eLBEF186PzaRfzLfutFYUq9MdiiIZbHejz+KML9rVInPJkc1tine3R3JQVuw1QBIQ2vhPNbGbHXWZg==
        pluginConfig:
          dynamicPlugins:
            frontend:
              janus-idp.backstage-plugin-orchestrator:
                appIcons:
                  - importName: OrchestratorIcon
                    module: OrchestratorPlugin
                    name: orchestratorIcon
                dynamicRoutes:
                  - importName: OrchestratorPage
                    menuItem:
                      icon: orchestratorIcon
                      text: Orchestrator
                    module: OrchestratorPlugin
                    path: /orchestrator
```

The versions of the plugins may undergo updates, leading to changes in their integrity values. To ensure you are utilizing the latest versions, please consult the Helm chart values available [here](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/charts/orchestrator/templates/rhdh-operator.yaml#L159)). It's imperative to set both the version and integrity values accordingly.

Additionally, ensure that the `dataIndexService.url` points to the service of the Data Index installed by the Chart/Operator.
When installed by the Helm chart, it should point to `http://sonataflow-platform-data-index-service.sonataflow-infra`:
```bash
oc get svc -n sonataflow-infra sonataflow-platform-data-index-service -o jsonpath='http://{.metadata.name}.{.metadata.namespace}'
```

* **-app-config* ConfigMap: This ConfigMap used for configuring backstage. Please add/modify to include the following:
```yaml
app:
  backend:
    csp:
      script-src: ["'self'", "'unsafe-inline'", "'unsafe-eval'"]
      script-src-elem: ["'self'", "'unsafe-inline'", "'unsafe-eval'"]
      connect-src: ["'self'", 'http:', 'https:', 'data:']
    cors:
      origin: {{ URL to RHDH service or route }}
```

To enable the Notifications plugin, edit the same ConfigMaps.
For the `dynamic-plugins` ConfigMap add:
```yaml
    plugins:
      - disabled: false
        package: "@janus-idp/plugin-notifications@1.2.5"
        integrity: sha512-BQ7ujmrbv2MLelNGyleC4Z8fVVywYBMYZTwmRC534WCT38QHQ0cWJbebOgeIYszFA98STW4F5tdKbVot/2gWMg==
        pluginConfig:
          dynamicPlugins:
            frontend:
              janus-idp.backstage-plugin-notifications:
                appIcons:
                  - name: notificationsIcon
                    module: NotificationsPlugin
                    importName: NotificationsActiveIcon
                dynamicRoutes:
                  - path: /notifications
                    importName: NotificationsPage
                    module: NotificationsPlugin
                    menuItem:
                      icon: notificationsIcon
                      text: Notifications
                    config:
                      pollingIntervalMs: 5000
      - disabled: false
        package: "@janus-idp/plugin-notifications-backend-dynamic@1.4.11"
        integrity: sha512-5zluThJwFVKX0Wlh4E15vDKUFGu/qJ0UsxHYWoISJ+ing1R38gskvN3kukylNTgOp8B78OmUglPfNlydcYEHvA==
```

For the `*-app-config` ConfigMap add the database configuration if isn't already provided. It is required for the notifications plugin:
```yaml
    app:
      title: Red Hat Developer Hub
      baseUrl: {{ URL to RHDH service or route }}
    backend:
      database:
        client: pg
        connection:
          password: ${POSTGRESQL_ADMIN_PASSWORD}
          user: ${POSTGRES_USER}
          host: ${POSTGRES_HOST}
          port: ${POSTGRES_PORT}
```
If persistence is enabled (which should be the default setting), ensure that the PostgreSQL environment variables are accessible.

Once the ConfigMaps have been updated, it is necessary to restart the RHDH instance to implement the changes effectively.

To import the Orchestrator software templates into the catalog via the Backstage UI, follow the instructions outlined in this [document](https://backstage.io/docs/features/software-templates/adding-templates). Register new templates into the catalog from the specified [source](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/charts/orchestrator/templates/rhdh-operator.yaml#L257)

## Upgrade plugin versions

To perform an upgrade of the plugin versions, start by acquiring the new plugin version along with its associated integrity value.
In the future, this section will be updated to reference the Red Hat NPM registry. However, at present, it directs to @janus-idp NPM packages on https://registry.npmjs.com.
The following script is useful to obtain the required information for updating the plugin version:

```bash
#!/bin/bash

PLUGINS=(
  "@janus-idp/plugin-notifications"
  "@janus-idp/plugin-notifications-backend-dynamic"
  "@janus-idp/backstage-plugin-orchestrator"
  "@janus-idp/backstage-plugin-orchestrator-backend-dynamic"
)

for PLUGIN_NAME in "${PLUGINS[@]}"
do
    echo "Processing plugin: $PLUGIN_NAME"
    curl -s -q "https://registry.npmjs.com/${PLUGIN_NAME}" | \
    jq -r '.versions | keys_unsorted[-1] as $latest_version | .[$latest_version] | "\(.name)\n\(.version)\n\(.dist.integrity)"'
    echo
done
```

A sample output should look like:
```
Processing plugin: @janus-idp/plugin-notifications
@janus-idp/plugin-notifications
1.1.12
sha512-GCdEuHRQek3ay428C8C4wWgxjNpNwCXgIdFbUUFGCLLkBFSaOEw+XaBvWaBGtQ5BLgE3jQEUxa+422uzSYC5oQ==

Processing plugin: @janus-idp/plugin-notifications-backend-dynamic
@janus-idp/plugin-notifications-backend-dynamic
1.3.6
sha512-Qd8pniy1yRx+x7LnwjzQ6k9zP+C1yex24MaCcx7dGDPT/XbTokwoSZr4baSSn8jUA6P45NUUevu1d629mG4JGQ==

Processing plugin: @janus-idp/backstage-plugin-orchestrator
@janus-idp/backstage-plugin-orchestrator
1.7.8
sha512-wJtu4Vhx3qjEiTe/i0Js2Jc0nz8B3ZIImJdul02KcyKmXNSKm3/rEiWo6AKaXUk/giRYscZQ1jTqlw/nz7xqeQ==

Processing plugin: @janus-idp/backstage-plugin-orchestrator-backend-dynamic
@janus-idp/backstage-plugin-orchestrator-backend-dynamic
1.5.3
sha512-l1MJIrZeXp9nOQpxFF5cw1ItOgA/p4xhGjKN12sg4Re8GC1qL+5hik+lA1BjMxAN6nKGWsLdFkgqLWa6jQuQFw==
```

After editing the version and integrity values in the *dynamic-plugins* ConfigMap, restart the Backstage instance for changes to take effect.
