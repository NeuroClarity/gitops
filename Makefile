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

HOSTED_ZONE=Z00792213KSNXYOGBGHZV

ifeq ($(ENV), dev)
	LANDING_DNS_NAME=dev.neuroclarity.ai
else
	LANDING_DNS_NAME=neuroclarity.ai
endif
LANDING_KUB_SVC=$(ENV)-landing-service

ifeq ($(ENV), dev)
	SYNAPSE_DNS_NAME=beta.$(ENV).neuroclarity.ai
else
	SYNAPSE_DNS_NAME=beta.neuroclarity.ai
endif
SYNAPSE_KUB_SVC=$(ENV)-synapse-argon-service

ifeq ($(ENV), dev)
	AXON_DNS_NAME=axon.$(ENV).neuroclarity.ai
else
	AXON_DNS_NAME=axon.neuroclarity.ai
endif
AXON_KUB_SVC=$(ENV)-axon-marketplace-service

ifeq ($(ENV), dev)
	NEURON_DNS_NAME=neuron.$(ENV).neuroclarity.ai
else
	NEURON_DNS_NAME=neuron.neuroclarity.ai
endif
NEURON_KUB_SVC=$(ENV)-neuron-service

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

#############
#  Routing  #
#############

.PHONY: update-landing-alias-records
update-landing-alias-records: check-env
	HOSTED_ZONE="$(HOSTED_ZONE)" \
	KUB_SVC="$(LANDING_KUB_SVC)" \
	DNS_NAME="$(LANDING_DNS_NAME)" \
	ENV="$(ENV)" \
	./scripts/route53.sh

.PHONY: update-synapse-alias-records
update-synapse-alias-records: check-env
	HOSTED_ZONE="$(HOSTED_ZONE)" \
	KUB_SVC="$(SYNAPSE_KUB_SVC)" \
	DNS_NAME="$(SYNAPSE_DNS_NAME)" \
	ENV="$(ENV)" \
	./scripts/route53.sh

.PHONY: update-axon-alias-records
update-axon-alias-records: check-env
	HOSTED_ZONE="$(HOSTED_ZONE)" \
	KUB_SVC="$(AXON_KUB_SVC)" \
	DNS_NAME="$(AXON_DNS_NAME)" \
	ENV="$(ENV)" \
	./scripts/route53.sh

.PHONY: update-neuron-alias-records
update-neuron-alias-records: check-env
	HOSTED_ZONE="$(HOSTED_ZONE)" \
	KUB_SVC="$(NEURON_KUB_SVC)" \
	DNS_NAME="$(NEURON_DNS_NAME)" \
	ENV="$(ENV)" \
	./scripts/route53.sh

.PHONY: update-all-alias-records
update-all-alias-records: update-landing-alias-records update-synapse-alias-records update-axon-alias-records update-neuron-alias-records
