PODMAN=podman

CONTAINER_IMG_NAME=frigate
CONTAINER_IMG_TAG=latest
CONTAINER=$(CONTAINER_IMG_NAME):$(CONTAINER_IMG_TAG)

HELM_CONTAINER_IMG_NAME=orchestrator-helm
HELM_CONTAINER=$(HELM_CONTAINER_IMG_NAME):$(CONTAINER_IMG_TAG)


build-helm:
	$(PODMAN) build -t $(HELM_CONTAINER) -f resources/helm-dockerfile .

build-frigate:
	$(PODMAN) build -t $(CONTAINER) -f resources/frigate-dockerfile .

generate-docs: build-frigate build-helm
	$(PODMAN) run --rm -v $(PWD):/app/:z $(CONTAINER) frigate gen --no-deps /app/charts/orchestrator/ > charts/orchestrator/README.md
	$(PODMAN) run --rm -v $(PWD):/app/:z $(HELM_CONTAINER) schema --input /app/charts/orchestrator/values.yaml --output /app/charts/orchestrator/values.schema.json

