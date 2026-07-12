SHELL := /bin/bash

TAG ?= v1
COUNT ?= 1

.PHONY: \
	build-push \
	deploy-image \
	shared-image \
	new-service \
	scale \
	blue-green \
	destroy-build-push \
	destroy-deploy-image \
	destroy-shared-image \
	destroy-new-service \
	destroy-scale-service \
	destroy-blue-green \
	destroy-all

build-push:
	./scripts/build-push-ecr.sh "$(TAG)"

deploy-image:
	./scripts/deploy-by-image-tag.sh "$(TAG)"

shared-image:
	./scripts/shared-image.sh "$(TAG)"

new-service:
	./scripts/new-service.sh "$(TAG)"

scale:
	./scripts/scale-service.sh "$(COUNT)" "$(TAG)"

blue-green:
	./scripts/blue-green.sh "$(TAG)"

destroy-build-push:
	terraform -chdir=infra/labs/build-push-ecr destroy -auto-approve

destroy-deploy-image:
	terraform -chdir=infra/labs/deploy-by-image-tag destroy \
		-var="image_tag=$(TAG)" \
		-auto-approve

destroy-shared-image:
	terraform -chdir=infra/labs/shared-image destroy \
		-var="image_tag=$(TAG)" \
		-auto-approve

destroy-new-service:
	terraform -chdir=infra/labs/new-service destroy \
		-var="image_tag=$(TAG)" \
		-auto-approve

destroy-scale-service:
	terraform -chdir=infra/labs/scale-service destroy -auto-approve

destroy-blue-green:
	terraform -chdir=infra/labs/blue-green destroy \
		-var="image_tag=$(TAG)" \
		-auto-approve

destroy-all:
	./scripts/destroy-all.sh