# helper rule to ensure ENV is set
check-env:
ifndef ENV
	$(error ENV not set, allowed values - `dev` or `prod`)
endif

# helper rule to ensure APP is set
check-app:
ifndef APP
	$(error APP not set, allowed values - `haven`, `wind`, `zephyr`, `airflow`, `jupyterhub`)
endif

.PHONY: get-logs
## get-logs: displays logs to stdout based off ENV and APP
get-logs: check-env check-app
	@echo "$(APP) logs for '$(ENV)'..."
	kubectl get pods --namespace $(ENV) | \
		grep "$(ENV)-$(APP)" | cut -d ' ' -f 1 | \
		xargs -t kubectl logs --namespace $(ENV)

.PHONY: deploy
## deploy: builds config and applys to k8s
deploy: check-env
	@cd "deploy/$(ENV)" && \
		kustomize build . | kubectl apply -f -

#############
#  Cluster  #
#############


.PHONY: create-cluster
## create-cluster: creates the production cluster in EKS
create-cluster:
	cd "deploy/bases/cluster" && \
	eksctl create cluster -f "neuroclarity.yaml" && \
	kubectl apply -f cluster-role.yaml && \
	kubectl create namespace dev && \
	kubectl create namespace prod

.PHONY: get-cloudformation-stack
## get-cloudformation-stack: gets a list of cloudformation templates
get-cloudformation-stack:
	@aws cloudformation list-stacks --query "StackSummaries[].StackName"


.PHONY: delete-cloudformation-stack
## delete-cloudformation-stack: destructive cleanup of existing cloudformation templates
delete-cloudformation-stack: check-env
	@aws cloudformation delete-stack --stack-name "eksctl-$(ENV)-serotiny-small-cluster" && \
		aws cloudformation delete-stack --stack-name "eksctl-$(ENV)-serotiny-small-nodegroup-serotiny-ng-1"


.PHONY: describe-stacks
## describe-stacks: shows the templates and variables used to setup the cluster
describe-stacks: 
	@eksctl utils describe-stacks --region=us-west-2 --cluster=nc-small
