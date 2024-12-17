# Installing PostgreSQL Server

Below there are two options to install PostgreSQL Server v15 on OCP cluster.
Both options shouldn't be used in production.

# Using Bitnami helm chart
Follow these steps to deploy a sample PostgreSQL instance in the `sonataflow-infra` namespace, with minimal requirements to deploy the Orchestrator.

Note: replace the password of the `sonataflow-psql-postgresql` secret below in the following command with the desired one.

```bash
oc new-project sonataflow-infra
oc create secret generic sonataflow-psql-postgresql --from-literal=postgres-username=postgres --from-literal=postgres-password=postgres

git clone git@github.com:rhdhorchestrator/orchestrator-helm-chart.git
cd orchestrator-helm-chart/postgresql
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install sonataflow-psql bitnami/postgresql --version 12.x.x -f ./values.yaml
```

#### **Note:** the default settings provided in [PostgreSQL values](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/main/postgresql/values.yaml) match the defaults provided in the [Orchestrator values](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/main/charts/orchestrator/values.yaml). 
Any changes to the first configuration must also be reported in the latter.

For OpenShift-related configuration in the chart visit [here](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/README.md#differences-between-bitnami-postgresql-image-and-docker-official-image).

In this installation, the image is `docker.io/bitnami/postgresql`.

# Using PostgreSQL image from RH Catalog

To install PostgreSQL based on RH [image](https://catalog.redhat.com/software/containers/rhel9/postgresql-15/63f763f779eb1214c4d6fcf6?architecture=amd64&image=65e0af6ed6fed9d9cb59fffd) follow these [steps](https://github.com/sclorg/postgresql-container/tree/master/15):

```bash
git clone https://github.com/sclorg/postgresql-container.git
cd postgresql-container/

oc process -f examples/postgresql-persistent-template.json \
   -p POSTGRESQL_VERSION=15 \
   -p POSTGRESQL_USER=postgres -p POSTGRESQL_PASSWORD=postgres \
   -p POSTGRESQL_DATABASE=sonataflow \
   -p VOLUME_CAPACITY=2Gi \
   -p DATABASE_SERVICE_NAME=sonataflow-psql-postgresql | oc create -n sonataflow-infra -f -

oc set image deployment/sonataflow-psql-postgresql -n sonataflow-infra postgresql=registry.redhat.io/rhel9/postgresql-15

oc wait -n sonataflow-infra deploy/sonataflow-psql-postgresql --for=condition=Available --timeout=5m

# Create the database
# Replace with the actual pod name
oc exec -i sonataflow-psql-postgresql-xyz -- psql -U postgres -d postgres <<EOF
CREATE DATABASE sonataflow;
GRANT ALL PRIVILEGES ON DATABASE sonataflow TO postgres;
EOF
```

Installing the Orchestrator chart should use the [values-rh-postgres.yaml](https://github.com/rhdhorchestrator/orchestrator-helm-chart/blob/main/charts/orchestrator/values-rh-postgres.yaml) that contains the updated
secret keys according to the `examples/postgresql-persistent-template.json` template used to create the database server.
Run installation by adding `-f orchestrator/values-rh-postgres.yaml`:
```
helm upgrade -i orchestrator orchestrator/orchestrator --set rhdhOperator.github.token=$GITHUB_TOKEN -f values.yaml -f values-rh-postgres.yaml
```

Note: there should have been a use of imagestream, but the referenced repository doesn't include instructions for using it,
In this installation, the image is `registry.redhat.io/rhel9/postgresql-15` which requires the global pull-secret to include access to `registry.redhat.io`.
