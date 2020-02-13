#  Prefer long args to short args for readability
ROOT_DIR    := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
DOCKER       = docker
HUGO_VERSION = 0.62.2
DOCKER_IMAGE = corda-docs-hugo
PROD_IMAGE   = corda-docs-nginx
NODE_IMAGE   = corda-docs-node
DOCKER_RUN   = $(DOCKER) run --rm --volume $(ROOT_DIR):/src
# DOCKER_RUN   = $(DOCKER) run --rm --interactive --tty --volume $(CURDIR):/src

.PHONY: all build build-preview help serve repos convert

clean: ## Remove (temp) repos
	rm -rf $(ROOT_DIR)/repos $(ROOT_DIR)/public

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

repos: ## Run clone repo script
	$(ROOT_DIR)/scripts/get_repos.sh

convert: ## Run rst->xml->md script
	python3 $(ROOT_DIR)/scripts/run_sphinx.py

serve: ## Build and serve hugo locally
	hugo serve -D -F --disableFastRender

build: ## Build the (prod) site
	hugo --minify

build-preview: ## Build site with drafts and future posts enabled
	hugo --buildDrafts --buildFuture

docker-image: ## Build hugo docker image
	$(DOCKER) build . --tag $(DOCKER_IMAGE) --build-arg HUGO_VERSION=$(HUGO_VERSION)

docker-build: ## Run hugo build in docker
	$(DOCKER_RUN) $(DOCKER_IMAGE) hugo

docker-serve: ## Serve site from docker
	$(DOCKER_RUN) -it -p 1313:1313 $(DOCKER_IMAGE) hugo server --buildFuture --buildDrafts --disableFastRender --bind 0.0.0.0

prod-docker-build: ## Prod build, minimal size
	$(DOCKER_RUN) $(DOCKER_IMAGE) hugo --minify

prod-docker-image: ## Create the prod docker image
	$(DOCKER) build . --tag $(PROD_IMAGE) -f prod/Dockerfile

prod-docker-serve: prod-docker-image ## Run the nginx container locally on port 8888
	$(DOCKER_RUN) -it -p "8888:80" $(PROD_IMAGE)

prod-docker-publish: ## Publish to prod docker registry
	echo "TODO"

prod-site: prod-docker-build prod-docker-image ## Make the prod site docker image ready for deployment
	echo "Built prod image"


node-image: ## Build node image
	$(DOCKER) build . --tag $(NODE_IMAGE) -f search/Dockerfile

node-build: ## Run node build in docker
	$(DOCKER_RUN) $(NODE_IMAGE) search/generate.sh

all: help
	echo ""
