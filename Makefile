.SILENT:
################################################################################
# Global defines
################################################################################

# COLORS http://invisible-island.net/xterm/xterm.faq.html#other_versions
RED  := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
MAGENTA  := $(shell tput -Txterm setaf 5)
CYAN  := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

# new line and tab
define NEWLINE


endef

define TAB

endef

################################################################################
# Output current makefile info
################################################################################
Function= ${YELLOW}IT IS Working ON my "LOCALHOST" ${MAGENTA}@ https://goo.gl/F3Y9xW${RESET}
RunRtfm = Run 'make rtfm' to see usage
RunHelp = Run 'make help' to see usage
$(info --------------------------------------------------------------------------------)
$(info ${RED}WHY:${RESET} ${GREEN}$(Function)$(NEWLINE)$(TAB)$(TAB)${GREEN}$(RunRtfm)${RESET})
$(info --------------------------------------------------------------------------------)

# get current folder name
# support call makefile from anywhere, not only from current path of makefile located
# MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
# CURRENT_DIR := $(notdir $(patsubst %/,%,$(MAKEFILE_DIR))
MAKEFILE_LIST_LASTWORD = $(lastword $(MAKEFILE_LIST))
MAKEFILE_PATH := $(abspath $(MAKEFILE_LIST_LASTWORD))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))
MAKEFILE_DIR_PATSUBST := $(patsubst %/,%,$(MAKEFILE_DIR))
MAKEFILE_DIR_NOSLASH = $(MAKEFILE_DIR_PATSUBST)
CURRENT_DIR = $(MAKEFILE_DIR)
CURRENT_DIR_NOSLASH = $(MAKEFILE_DIR_NOSLASH)
CURRENT_DIR_NAME := $(notdir $(MAKEFILE_DIR_PATSUBST))

SHELL := $(shell which bash 2>/dev/null)
CURL := $(shell which curl 2>/dev/null)
PWD := $(shell pwd)


.DEFAULT_GOAL := help

.PHONY : help rtfm
.PHONY : prepare
.PHONY : start-minikube

## SEE RTFM @ https://en.wikipedia.org/wiki/RTFM
rtfm:

RANDOM := $(shell od -An -N2 -i /dev/random | tr -d ' ')
IMAGEID = 1.0


## prepare
prepare:
	@./infra/scripts/prepare.sh


## minikube
minikube-start:
	@eval $(minikube docker-env)
	@minikube start
	@minikube status
	@minikube addons enable ingress
	@minikube addons enable ingress-dns
	@minikube addons enable metrics-server
	@kubectl config --kubeconfig=config set-context minikube --cluster=minikube
	@kubectl config use-context minikube

## Access the Kubernetes dashboard running within the minikube cluster
minikube-dashboard:
	@eval $(minikube docker-env)
	@minikube dashboard --url=true

## deploy grafana and prometheus with helm official helm chart
monitoring:
	@eval $(minikube docker-env)
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm upgrade --install  prometheus prometheus-community/prometheus --set server.statefulSet.enabled=true -f infra/monitoring/prometheus-values.yaml
	@helm repo add grafana https://grafana.github.io/helm-charts
	@helm upgrade --install grafana grafana/grafana --set persistence.type=statefulset,persistence.enabled=true -f infra/monitoring/grafana-values.yaml
	@helm upgrade --install kafka-exporter prometheus-community/prometheus-kafka-exporter --set kafkaServer="{kafka-0.kafka-headless.kafka.svc.cluster.local:9092,kafka-1.kafka-headless.kafka.svc.cluster.local:9092,kafka-2.kafka-headless.kafka.svc.cluster.local:9092}" \
	  --set-string service.annotations.'prometheus\.io/path'="/metrics",service.annotations.'prometheus\.io/scrape'="true",service.annotations.'prometheus\.io/port'="9308"

## kafka
kafka:
	@eval $(minikube docker-env)
	@kubectl apply -f infra/kafka/namespace.yaml
	@kubectl apply -f infra/kafka/

## docker build
build:
	@eval $(minikube docker-env)
	@docker build --platform linux/amd64 -t demo/consumer:$(IMAGEID) -f consumer/Dockerfile .
	@docker build --platform linux/amd64 -t demo/producer:$(IMAGEID) -f producer/Dockerfile .

## build and deploy app
deploy:
	@eval $(minikube docker-env)
	@minikube image load demo/consumer:$(IMAGEID)
	@helm upgrade -i consumer ./infra/helm/app --set-string 'image.tag=$(IMAGEID)' --set-string 'image.repository=demo/consumer'
	@minikube image load demo/producer:$(IMAGEID)
	@helm upgrade -i producer ./infra/helm/app --set-string 'image.tag=$(IMAGEID)' --set-string 'image.repository=demo/producer'

## port forwarding to access the grafana
grafana-ui:
	@eval $(minikube docker-env)
	@kubectl port-forward service/grafana 8000:80

## port forwarding to access the kafdrop
kafdrop-ui:
	@eval $(minikube docker-env)
	@kubectl port-forward service/kafdrop 9000:9000 -n kafka

## delete minikube setup
minikube-delete:
	@minikube delete && rm -rf ~/.minikube

## stop minikube
minikube-stop:
	@eval $(minikube docker-env)
	@minikube stop



################################################################################
# Help
################################################################################

TARGET_MAX_CHAR_NUM=25
## Show help
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)