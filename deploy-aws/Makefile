# Makefile for AnythingLLM AWS Deployment

# Variables
STACK_NAME ?= anythingllm
REGION ?= us-east-1
TEMPLATE_FILE = cloudformation/anythingllm-ecs-stack.yaml
PARAMS_FILE = cloudformation/personal-parameters.json
SAMPLE_PARAMS_FILE = cloudformation/anythingllm-params-sample.json

# Colors for pretty output
BLUE := \033[34m
GREEN := \033[32m
RED := \033[31m
YELLOW := \033[33m
RESET := \033[0m

# Default target
.PHONY: help
help:
	@echo "$(BLUE)AnythingLLM AWS Deployment Makefile$(RESET)"
	@echo ""
	@echo "Available targets:"
	@echo "  $(GREEN)help$(RESET)              - Show this help message"
	@echo "  $(GREEN)check-tools$(RESET)       - Check if required tools are installed"
	@echo "  $(GREEN)generate-secrets$(RESET)  - Generate secure random values"
	@echo "  $(GREEN)create-params$(RESET)     - Create personal parameters file"
	@echo "  $(GREEN)validate$(RESET)          - Validate CloudFormation template"
	@echo "  $(GREEN)deploy$(RESET)            - Deploy the stack to AWS"
	@echo "  $(GREEN)update$(RESET)            - Update an existing stack"
	@echo "  $(GREEN)delete$(RESET)            - Delete the stack"
	@echo "  $(GREEN)describe$(RESET)          - Describe the current stack"
	@echo "  $(GREEN)outputs$(RESET)           - Show stack outputs"
	@echo "  $(GREEN)build-image$(RESET)       - Build Docker image"
	@echo "  $(GREEN)push-image$(RESET)        - Push Docker image to ECR"
	@echo "  $(GREEN)all$(RESET)               - Complete deployment workflow"
	@echo ""
	@echo "Variables:"
	@echo "  STACK_NAME = $(STACK_NAME)"
	@echo "  REGION = $(REGION)"
	@echo ""
	@echo "Example:"
	@echo "  make deploy STACK_NAME=my-anythingllm REGION=us-west-2"

# Check for required tools
.PHONY: check-tools
check-tools:
	@echo "$(BLUE)Checking for required tools...$(RESET)"
	@which aws >/dev/null || (echo "$(RED)Error: AWS CLI not found. Please install it.$(RESET)" && exit 1)
	@which docker >/dev/null || (echo "$(RED)Error: Docker not found. Please install it.$(RESET)" && exit 1)
	@which openssl >/dev/null || (echo "$(RED)Error: OpenSSL not found. Please install it.$(RESET)" && exit 1)
	@echo "$(GREEN)All required tools are available.$(RESET)"

# Generate secure random values
.PHONY: generate-secrets
generate-secrets:
	@echo "$(BLUE)Generating secure random values...$(RESET)"
	@scripts/generate-secrets.sh --output $(PARAMS_FILE)

# Create personal parameters file from sample
.PHONY: create-params
create-params:
	@if [ ! -f "$(PARAMS_FILE)" ]; then \
		echo "$(BLUE)Creating $(PARAMS_FILE) from $(SAMPLE_PARAMS_FILE)...$(RESET)"; \
		cp $(SAMPLE_PARAMS_FILE) $(PARAMS_FILE); \
		chmod 600 $(PARAMS_FILE); \
		echo "$(GREEN)Created $(PARAMS_FILE). Please edit it with your actual values.$(RESET)"; \
	else \
		echo "$(YELLOW)$(PARAMS_FILE) already exists. Not overwriting.$(RESET)"; \
	fi

# Validate CloudFormation template
.PHONY: validate
validate:
	@echo "$(BLUE)Validating CloudFormation template...$(RESET)"
	@aws cloudformation validate-template \
		--template-body file://$(TEMPLATE_FILE) \
		--region $(REGION) || \
		(echo "$(RED)Template validation failed.$(RESET)" && exit 1)
	@echo "$(GREEN)Template validation successful.$(RESET)"

# Deploy the stack
.PHONY: deploy
deploy: check-tools validate
	@if [ ! -f "$(PARAMS_FILE)" ]; then \
		echo "$(RED)Error: $(PARAMS_FILE) not found!$(RESET)"; \
		echo "Run 'make create-params' first."; \
		exit 1; \
	fi
	@echo "$(BLUE)Deploying stack $(STACK_NAME)...$(RESET)"
	@aws cloudformation deploy \
		--template-file $(TEMPLATE_FILE) \
		--stack-name $(STACK_NAME) \
		--parameter-overrides file://$(PARAMS_FILE) \
		--capabilities CAPABILITY_IAM \
		--region $(REGION)
	@echo "$(GREEN)Deployment completed.$(RESET)"
	@make outputs

# Update an existing stack
.PHONY: update
update: check-tools validate
	@echo "$(BLUE)Updating stack $(STACK_NAME)...$(RESET)"
	@aws cloudformation update-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters file://$(PARAMS_FILE) \
		--capabilities CAPABILITY_IAM \
		--region $(REGION)
	@echo "$(GREEN)Update initiated.$(RESET)"

# Delete the stack
.PHONY: delete
delete:
	@echo "$(RED)Are you sure you want to delete stack '$(STACK_NAME)'? [y/N]$(RESET)" && read ans && [ $${ans:-N} = y ]
	@echo "$(BLUE)Deleting stack $(STACK_NAME)...$(RESET)"
	@aws cloudformation delete-stack \
		--stack-name $(STACK_NAME) \
		--region $(REGION)
	@echo "$(GREEN)Deletion initiated.$(RESET)"

# Describe the current stack
.PHONY: describe
describe:
	@echo "$(BLUE)Describing stack $(STACK_NAME)...$(RESET)"
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION)

# Show stack outputs
.PHONY: outputs
outputs:
	@echo "$(BLUE)Outputs for stack $(STACK_NAME):$(RESET)"
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--query 'Stacks[0].Outputs' \
		--output table \
		--region $(REGION)

# Build Docker image
.PHONY: build-image
build-image: check-tools
	@echo "$(BLUE)Building Docker image...$(RESET)"
	@cd .. && docker build -t anythingllm:latest -f docker/Dockerfile .
	@echo "$(GREEN)Docker image built successfully.$(RESET)"

# Push Docker image to ECR
.PHONY: push-image
push-image: check-tools
	@echo "$(BLUE)Setting up ECR and pushing image...$(RESET)"
	@scripts/setup-ecr.sh --region $(REGION)

# Validate deployment
.PHONY: validate-deployment
validate-deployment:
	@echo "$(BLUE)Validating deployment...$(RESET)"
	@scripts/validate-deployment.sh --stack $(STACK_NAME) --region $(REGION)

# Complete deployment workflow
.PHONY: all
all: check-tools generate-secrets validate build-image push-image deploy validate-deployment
	@echo "$(GREEN)All deployment steps completed!$(RESET)"
	@echo "$(BLUE)Stack Outputs:$(RESET)"
	@make outputs

# Clean up generated files
.PHONY: clean
clean:
	@echo "$(YELLOW)Cleaning up generated files...$(RESET)"
	@rm -f cloudformation/ecr-repository-url.txt
	@echo "$(GREEN)Cleanup complete.$(RESET)"

# Print the current configuration
.PHONY: config
config:
	@echo "$(BLUE)Current Configuration:$(RESET)"
	@echo "Stack Name: $(STACK_NAME)"
	@echo "Region: $(REGION)"
	@echo "Template File: $(TEMPLATE_FILE)"
	@echo "Parameters File: $(PARAMS_FILE)"
	@echo "Sample Parameters File: $(SAMPLE_PARAMS_FILE)"
