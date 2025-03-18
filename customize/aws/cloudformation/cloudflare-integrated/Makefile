# Makefile for managing AnythingLLM CloudFormation stack with Cloudflare integration

# Default stack name
STACK_NAME ?= anythingllm-cloudflare

# Paths
SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PARAMS_FILE := $(SCRIPT_DIR)parameters.json
TEMPLATE_FILE := $(SCRIPT_DIR)template.yaml

# Required tools
REQUIRED_TOOLS := jq curl aws

# Colors for output
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help check-deps update-cf-ips update-stack

help:
	@echo "Available targets:"
	@echo "  help              - Show this help message"
	@echo "  check-deps        - Check for required dependencies"
	@echo "  update-cf-ips     - Update Cloudflare IP ranges in parameters.json"
	@echo "  update-stack      - Update CloudFormation stack with new parameters"
	@echo ""
	@echo "Usage:"
	@echo "  make update-stack STACK_NAME=your-stack-name"

check-deps:
	@for tool in $(REQUIRED_TOOLS); do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			echo "$(RED)Error: $$tool is required but not installed.$(NC)"; \
			if [ "$$tool" = "jq" ]; then \
				echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"; \
			fi; \
			exit 1; \
		fi; \
	done
	@echo "$(GREEN)All dependencies are installed.$(NC)"

update-cf-ips: check-deps
	@echo "Fetching Cloudflare IP ranges..."
	@CF_IPS=$$(curl -s https://www.cloudflare.com/ips-v4 | tr '\n' ',' | sed 's/,$$//'); \
	if [ -z "$$CF_IPS" ]; then \
		echo "$(RED)Error: Failed to fetch Cloudflare IP ranges$(NC)"; \
		exit 1; \
	fi; \
	TMP_FILE=$$(mktemp); \
	if jq --arg ips "$$CF_IPS" ' \
		map( \
			if .ParameterKey == "AllowedCloudflareIPs" then \
				.ParameterValue = $$ips \
			else \
				. \
			end \
		)' "$(PARAMS_FILE)" > "$$TMP_FILE"; then \
		mv "$$TMP_FILE" "$(PARAMS_FILE)"; \
		echo "$(GREEN)Successfully updated parameters.json$(NC)"; \
	else \
		rm "$$TMP_FILE"; \
		echo "$(RED)Error: Failed to update parameters.json$(NC)"; \
		exit 1; \
	fi

update-stack: check-deps update-cf-ips
	@echo "Updating CloudFormation stack: $(STACK_NAME)..."
	@if aws cloudformation update-stack \
		--stack-name "$(STACK_NAME)" \
		--template-body "file://$(TEMPLATE_FILE)" \
		--parameters "file://$(PARAMS_FILE)" \
		--capabilities CAPABILITY_IAM; then \
		echo "$(GREEN)Stack update initiated successfully$(NC)"; \
		echo "Monitor the update status in AWS Console or use:"; \
		echo "aws cloudformation describe-stacks --stack-name $(STACK_NAME)"; \
	else \
		echo "$(RED)Error: Failed to update stack$(NC)"; \
		exit 1; \
	fi

# Default target
.DEFAULT_GOAL := help
