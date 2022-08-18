.PHONY: help dist-dev publish-dev dist-stage publish-stage dist publish stage promote
SHELL=/bin/bash
ECR_REGISTRY=672626379771.dkr.ecr.us-east-1.amazonaws.com
DATETIME:=$(shell date -u +%Y%m%dT%H%M%SZ)

### This is the Terraform-generated header for geoweb-dev ###
ECR_NAME_DEV:=geoweb-dev
ECR_URL_DEV:=222053980223.dkr.ecr.us-east-1.amazonaws.com/geoweb-dev
### End of Terraform-generated header ###

help: ## Print this message
	@awk 'BEGIN { FS = ":.*##"; print "Usage:  make <target>\n\nTargets:" } \
		/^[-_[:alpha:]]+:.?*##/ { printf "  %-15s%s\n", $$1, $$2 }' $(MAKEFILE_LIST)

### Terraform-generated Developer Deploy Commands for Dev environment ###
dist-dev: ## Build docker container (intended for developer-based manual build)
	docker build --platform linux/amd64 \
	    -t $(ECR_URL_DEV):latest \
		-t $(ECR_URL_DEV):`git log -1 --pretty=format:"%h"` \
		-t $(ECR_NAME_DEV):latest .

publish-dev: dist-dev ## Build, tag and push (intended for developer-based manual publish)
	docker login -u AWS -p $$(aws ecr get-login-password --region us-east-1) $(ECR_URL_DEV)
	docker push $(ECR_URL_DEV):latest
	docker push $(ECR_URL_DEV):`git log -1 --pretty=format:"%h"`

### Terraform-generated manual shortcuts for deploying to Stage ###
### This requires that ECR_NAME_STAGE & ECR_URL_STAGE environment variables are set locally
### by the developer and that the developer has authenticated to the correct AWS Account.
### The values for the environment variables can be found in the stage_build.yml caller workflow.
dist-stage: ## Only use in an emergency
	docker build --platform linux/amd64 \
	    -t $(ECR_URL_STAGE):latest \
		-t $(ECR_URL_STAGE):`git log -1 --pretty=format:"%h"` \
		-t $(ECR_NAME_STAGE):latest .

publish-stage: ## Only use in an emergency
	docker login -u AWS -p $$(aws ecr get-login-password --region us-east-1) $(ECR_URL_STAGE)
	docker push $(ECR_URL_STAGE):latest
	docker push $(ECR_URL_STAGE):`git log -1 --pretty=format:"%h"`

### Commands for legacy AWS
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
