
API_URL  = https://develop.ivcap.net
DOMAIN   = docs.develop.ivcap.net

ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# ── Directories ────────────────────────────────────────────────────────────────
CONTENT_DIR      := content
SDK_DIR          := $(CONTENT_DIR)/sdk
EXAMPLES_DIR     := $(CONTENT_DIR)/examples
CACHE_DIR        := .cache
SCRIPTS_DIR      := scripts

# ── Config files ───────────────────────────────────────────────────────────────
SDK_REGISTRY     := config/sdk-registry.json
EXAMPLE_REGISTRY := config/example-registry.json

# ── Tooling ────────────────────────────────────────────────────────────────────
PYTHON  := poetry run python3
MKDOCS  := poetry run mkdocs

# ── Colours ────────────────────────────────────────────────────────────────────
BOLD  := \033[1m
RESET := \033[0m
GREEN := \033[32m
CYAN  := \033[36m

# ──────────────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@echo ""
	@echo "  $(BOLD)IVCAP Docs Build System$(RESET)"
	@echo ""
	@echo "  $(CYAN)Setup$(RESET)"
	@echo "    install           Install Python dependencies via poetry"
	@echo ""
	@echo "  $(CYAN)Content fetching$(RESET)"
	@echo "    fetch             Fetch all content (SDK docs + examples)"
	@echo "    fetch-sdk         Fetch SDK narrative docs only"
	@echo "    fetch-examples    Fetch example repos only"
	@echo "    fetch-sdk SDK=python-service   Fetch a single SDK"
	@echo "    fetch-example EX=python-lambda Fetch a single example"
	@echo ""
	@echo "  $(CYAN)Building$(RESET)"
	@echo "    build             Build the full site (with fetch + nav)"
	@echo "    serve             Live-reload local dev server (no fetch needed)"
	@echo "    generate-nav      Regenerate mkdocs.yml nav from fetched content"
	@echo ""
	@echo "  $(CYAN)Quality$(RESET)"
	@echo "    validate          Validate all registry files"
	@echo "    check-links       Check for broken links in built site"
	@echo ""
	@echo "  $(CYAN)Deployment$(RESET)"
	@echo "    deploy            Build and deploy to IVCAP platform"
	@echo ""
	@echo "  $(CYAN)Housekeeping$(RESET)"
	@echo "    clean             Remove fetched content and build artefacts"
	@echo "    clean-cache       Remove git clone cache only"
	@echo ""

# ──────────────────────────────────────────────────────────────────────────────
# Setup
# ──────────────────────────────────────────────────────────────────────────────
.PHONY: install
install:
	@echo "$(BOLD)Installing dependencies via poetry...$(RESET)"
	poetry install
	@echo "$(GREEN)Done.$(RESET)"

# ──────────────────────────────────────────────────────────────────────────────
# Validation
# ──────────────────────────────────────────────────────────────────────────────
.PHONY: validate validate-sdk validate-examples
validate: validate-sdk validate-examples
	@echo "$(GREEN)All registries valid.$(RESET)"

validate-sdk:
	@echo "$(BOLD)Validating SDK registry...$(RESET)"
	@$(PYTHON) $(SCRIPTS_DIR)/validate_registry.py \
		--registry $(SDK_REGISTRY) \
		--schema config/sdk-schema.json

validate-examples:
	@echo "$(BOLD)Validating example registry...$(RESET)"
	@$(PYTHON) $(SCRIPTS_DIR)/validate_registry.py \
		--registry $(EXAMPLE_REGISTRY) \
		--schema config/example-schema.json

# ──────────────────────────────────────────────────────────────────────────────
# Fetching
# ──────────────────────────────────────────────────────────────────────────────
.PHONY: fetch fetch-sdk fetch-examples

fetch: fetch-sdk fetch-examples generate-nav
	@echo "$(GREEN)All content fetched.$(RESET)"

# Fetch all SDKs, or a single one: make fetch-sdk SDK=python-service
fetch-sdk:
	@echo "$(BOLD)Fetching SDK docs...$(RESET)"
	@mkdir -p $(SDK_DIR) $(CACHE_DIR)
ifdef SDK
	@$(PYTHON) $(SCRIPTS_DIR)/fetch_sdk.py \
		--registry $(SDK_REGISTRY) \
		--output $(SDK_DIR) \
		--cache $(CACHE_DIR) \
		--sdk $(SDK)
else
	@$(PYTHON) $(SCRIPTS_DIR)/fetch_sdk.py \
		--registry $(SDK_REGISTRY) \
		--output $(SDK_DIR) \
		--cache $(CACHE_DIR)
endif

# Fetch all examples, or one: make fetch-example EX=python-lambda
fetch-examples:
	@echo "$(BOLD)Fetching example repos...$(RESET)"
	@mkdir -p $(EXAMPLES_DIR) $(CACHE_DIR)
ifdef EX
	@$(PYTHON) $(SCRIPTS_DIR)/fetch_examples.py \
		--registry $(EXAMPLE_REGISTRY) \
		--output $(EXAMPLES_DIR) \
		--cache $(CACHE_DIR) \
		--example $(EX)
else
	@$(PYTHON) $(SCRIPTS_DIR)/fetch_examples.py \
		--registry $(EXAMPLE_REGISTRY) \
		--output $(EXAMPLES_DIR) \
		--cache $(CACHE_DIR)
endif

# ──────────────────────────────────────────────────────────────────────────────
# Nav generation (only run after fetch; mkdocs.yml is committed and works
# without fetched content for local development via 'make serve')
# ──────────────────────────────────────────────────────────────────────────────
.PHONY: generate-nav
generate-nav:
	@echo "$(BOLD)Generating nav from fetched content...$(RESET)"
	@$(PYTHON) $(SCRIPTS_DIR)/generate_nav.py \
		--sdk-dir $(SDK_DIR) \
		--examples-dir $(EXAMPLES_DIR) \
		--sdk-registry $(SDK_REGISTRY) \
		--example-registry $(EXAMPLE_REGISTRY) \
		--template config/mkdocs-template.yml \
		--output mkdocs.yml

# ──────────────────────────────────────────────────────────────────────────────
# Build & serve
# ──────────────────────────────────────────────────────────────────────────────
.PHONY: build serve

# Full CI build: fetch everything then build strictly
build: fetch
	@echo "$(BOLD)Building site...$(RESET)"
	$(MKDOCS) build --strict

# Local dev: just serve; mkdocs.yml already committed, no fetch required
serve:
	@echo "$(BOLD)Starting dev server...$(RESET)"
	@echo "  Tip: run $(CYAN)make fetch$(RESET) first to include pulled SDK/example content"
	$(MKDOCS) serve

# ──────────────────────────────────────────────────────────────────────────────
# Link checking
# ──────────────────────────────────────────────────────────────────────────────
.PHONY: check-links
check-links: build
	@echo "$(BOLD)Checking links...$(RESET)"
	@$(PYTHON) $(SCRIPTS_DIR)/check_links.py --site-dir site

# ──────────────────────────────────────────────────────────────────────────────
# Deploy to IVCAP platform
# ──────────────────────────────────────────────────────────────────────────────
.PHONY: deploy

$(ROOT_DIR)/$(DOMAIN).tgz: build
	cd $(ROOT_DIR)/site && tar zcf $(ROOT_DIR)/$(DOMAIN).tgz *

deploy: $(ROOT_DIR)/$(DOMAIN).tgz
	$(eval BUILD_ART=$(shell ivcap --silent artifact create --force -n $(DOMAIN) -f $(ROOT_DIR)/$(DOMAIN).tgz))
	@echo "ArtifactID: $(BUILD_ART)"
	echo "{\
		\"\$$schema\": \"urn:ivcap:schema:app-server.1\",\
		\"host\": \"$(DOMAIN)\",\
		\"artifact\": \"$(BUILD_ART)\",\
		\"404\": \"404.html\"\
	}" | ivcap --timeout 600 aspect update urn:ivcap:app-server:$(DOMAIN) -f -

# ──────────────────────────────────────────────────────────────────────────────
# Clean
# ──────────────────────────────────────────────────────────────────────────────
.PHONY: clean clean-cache
clean:
	@echo "$(BOLD)Cleaning fetched content and build artefacts...$(RESET)"
	rm -rf $(CONTENT_DIR) site $(ROOT_DIR)/$(DOMAIN).tgz
	@echo "$(GREEN)Done.$(RESET)"

clean-cache:
	@echo "$(BOLD)Clearing clone cache...$(RESET)"
	rm -rf $(CACHE_DIR)
	@echo "$(GREEN)Done.$(RESET)"
