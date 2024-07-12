PODMAN=podman
CONTAINER_IMG_NAME=frigate
CONTAINER_IMG_TAG=latest
CONTAINER=$(CONTAINER_IMG_NAME):$(CONTAINER_IMG_TAG)

build-frigate:
	$(PODMAN) build -t $(CONTAINER) -f resources/frigate-dockerfile .

generate-docs: build-frigate
	$(PODMAN) run -v $(PWD):/app/:z --rm $(CONTAINER) frigate gen --no-deps /app/charts/orchestrator/ > charts/orchestrator/README.md


