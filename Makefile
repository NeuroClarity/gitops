# helper rule to ensure ENV is set
check-env:
ifndef ENV
	$(error ENV not set, allowed values - `dev` or `prod`)
endif

# helper rule to ensure APP is set
check-app:
ifndef APP
	$(error APP not set, allowed values - `landing`, `synapse-argon`, `axon-marketplace`, `neuron`)
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

.PHONY: delete-cluster
## delete-cluster: deletes the production cluster in EKS
delete-cluster:
	cd "deploy/bases/cluster" && \
	eksctl delete cluster -f "neuroclarity.yaml"
