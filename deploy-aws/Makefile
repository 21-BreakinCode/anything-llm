.PHONY: help check-tools create-params validate update delete describe outputs

# Variables
STACK_NAME ?=
REGION ?=
TEMPLATE_FILE = cloudformation/anythingllm-ecs-stack.yaml
PARAMS_FILE = cloudformation/personal-parameters.json
SAMPLE_PARAMS_FILE = cloudformation/anythingllm-params-sample.json

# Disable AWS CLI paging
export AWS_PAGER=

# Colors for pretty output
BLUE := \033[34m
GREEN := \033[32m
RED := \033[31m
YELLOW := \033[33m
RESET := \033[0m


help:
	@echo "$(BLUE)AnythingLLM AWS Deployment Makefile$(RESET)"
	@echo ""
	@echo "Available targets:"
	@echo "  $(GREEN)help$(RESET)              - Show this help message"
	@echo "  $(GREEN)check-tools$(RESET)       - Check if required tools are installed"
	@echo "  $(GREEN)create-params$(RESET)     - Create personal parameters file"
	@echo "  $(GREEN)validate$(RESET)          - Validate CloudFormation template"
	@echo "  $(GREEN)deploy$(RESET)            - Deploy or update the stack"
	@echo "  $(GREEN)update$(RESET)            - Update an existing stack"
	@echo "  $(GREEN)delete$(RESET)            - Delete the stack and wait for completion"
	@echo "  $(GREEN)describe$(RESET)          - Describe the current stack"
	@echo "  $(GREEN)outputs$(RESET)           - Show stack outputs"
	@echo "  $(GREEN)clean$(RESET)             - Clean up generated files"
	@echo "  $(GREEN)config$(RESET)            - Print the current configuration"
	@echo ""
	@echo "Variables:"
	@echo "  STACK_NAME = $(STACK_NAME)"
	@echo "  REGION = $(REGION)"
	@echo ""
	@echo "Example:"
	@echo "  make deploy STACK_NAME=my-anythingllm REGION=us-west-2"

check-tools:
	@echo "$(BLUE)Checking for required tools...$(RESET)"
	@which aws >/dev/null || (echo "$(RED)Error: AWS CLI not found. Please install it.$(RESET)" && exit 1)
	@which docker >/dev/null || (echo "$(RED)Error: Docker not found. Please install it.$(RESET)" && exit 1)
	@which openssl >/dev/null || (echo "$(RED)Error: OpenSSL not found. Please install it.$(RESET)" && exit 1)
	@echo "$(GREEN)All required tools are available.$(RESET)"

create-params:
	@if [ ! -f "$(PARAMS_FILE)" ]; then \
		echo "$(BLUE)Creating $(PARAMS_FILE) from $(SAMPLE_PARAMS_FILE)...$(RESET)"; \
		cp $(SAMPLE_PARAMS_FILE) $(PARAMS_FILE); \
		chmod 600 $(PARAMS_FILE); \
		echo "$(GREEN)Created $(PARAMS_FILE). Please edit it with your actual values.$(RESET)"; \
	else \
		echo "$(YELLOW)$(PARAMS_FILE) already exists. Not overwriting.$(RESET)"; \
	fi

validate:
	@echo "$(BLUE)Validating CloudFormation template...$(RESET)"
	@aws cloudformation validate-template \
		--template-body file://$(TEMPLATE_FILE) \
		--region $(REGION) || \
		(echo "$(RED)Template validation failed.$(RESET)" && exit 1)
	@echo "$(GREEN)Template validation successful.$(RESET)"


deploy: check-tools validate
	@if [ ! -f "$(PARAMS_FILE)" ]; then \
		echo "$(RED)Error: $(PARAMS_FILE) not found!$(RESET)"; \
		echo "Run 'make create-params' first."; \
		exit 1; \
	fi
	@echo "$(BLUE)Creating stack $(STACK_NAME)...$(RESET)"
	@aws cloudformation create-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters file://$(PARAMS_FILE) \
		--capabilities CAPABILITY_IAM \
		--region $(REGION)
	@echo "$(BLUE)Waiting for stack create to complete...$(RESET)"
	@aws cloudformation wait stack-create-complete \
		--stack-name $(STACK_NAME) \
		--region $(REGION)
	@echo "$(GREEN)Stack update completed.$(RESET)"
	@make outputs

update: check-tools validate
	@if [ ! -f "$(PARAMS_FILE)" ]; then \
		echo "$(RED)Error: $(PARAMS_FILE) not found!$(RESET)"; \
		echo "Run 'make create-params' first."; \
		exit 1; \
	fi
	@echo "$(BLUE)Updating stack $(STACK_NAME)...$(RESET)"
	@aws cloudformation update-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters file://$(PARAMS_FILE) \
		--capabilities CAPABILITY_IAM \
		--region $(REGION)
	@echo "$(BLUE)Waiting for stack update to complete...$(RESET)"
	@aws cloudformation wait stack-update-complete \
		--stack-name $(STACK_NAME) \
		--region $(REGION)
	@echo "$(GREEN)Stack update completed.$(RESET)"
	@make outputs

delete:
	@echo "$(RED)Are you sure you want to delete stack '$(STACK_NAME)'? [y/N]$(RESET)" && read ans && [ $${ans:-N} = y ]
	@echo "$(BLUE)Deleting stack $(STACK_NAME)...$(RESET)"
	@aws cloudformation delete-stack \
		--stack-name $(STACK_NAME) \
		--region $(REGION)
	@echo "$(BLUE)Waiting for stack deletion to complete...$(RESET)"
	@aws cloudformation wait stack-delete-complete \
		--stack-name $(STACK_NAME) \
		--region $(REGION)
	@echo "$(GREEN)Stack deletion complete.$(RESET)"

describe:
	@echo "$(BLUE)Describing stack $(STACK_NAME)...$(RESET)"
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION)

outputs:
	@echo "$(BLUE)Outputs for stack $(STACK_NAME):$(RESET)"
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--query 'Stacks[0].Outputs' \
		--output table \
		--region $(REGION)
