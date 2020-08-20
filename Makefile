.PHONY: help dist publish stage promote
SHELL=/bin/bash
ECR_REGISTRY=672626379771.dkr.ecr.us-east-1.amazonaws.com
DATETIME:=$(shell date -u +%Y%m%dT%H%M%SZ)

help: ## Print this message
	@awk 'BEGIN { FS = ":.*##"; print "Usage:  make <target>\n\nTargets:" } \
		/^[-_[:alpha:]]+:.?*##/ { printf "  %-15s%s\n", $$1, $$2 }' $(MAKEFILE_LIST)

dist: ## Build docker image
	docker build -t $(ECR_REGISTRY)/geoblacklight-stage:latest \
		-t $(ECR_REGISTRY)/geoblacklight-stage:`git describe --always` \
		-t geoblacklight .

publish: ## Push and tag the latest image (use `make dist && make publish`)
	$$(aws ecr get-login --no-include-email --region us-east-1)
	docker push $(ECR_REGISTRY)/geoblacklight-stage:latest
	docker push $(ECR_REGISTRY)/geoblacklight-stage:`git describe --always`

stage: publish ## Deploy image to staging and redeploy service
	aws ecs update-service --cluster geoblacklight-stage --service geoblacklight-stage --force-new-deployment

promote: ## Promote the current staging build to production
	$$(aws ecr get-login --no-include-email --region us-east-1)
	docker pull $(ECR_REGISTRY)/geoblacklight-stage:latest
	docker tag $(ECR_REGISTRY)/geoblacklight-stage:latest $(ECR_REGISTRY)/geoblacklight-prod:latest
	docker tag $(ECR_REGISTRY)/geoblacklight-stage:latest $(ECR_REGISTRY)/geoblacklight-prod:$(DATETIME)
	docker push $(ECR_REGISTRY)/geoblacklight-prod:latest
	docker push $(ECR_REGISTRY)/geoblacklight-prod:$(DATETIME)
