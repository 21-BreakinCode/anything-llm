.PHONY: help check-image sync-env deploy-stack update-stack deploy update-env describe-service delete-stack clean-ssm clean

STACK_NAME ?= anythingllm
REGION ?= $(AWS_REGION)
VERBOSE ?= false

# Disable AWS CLI paging
export AWS_PAGER=

# Colors for pretty output
BLUE := \033[34m
GREEN := \033[32m
RED := \033[31m
YELLOW := \033[33m
RESET := \033[0m


help:
	@echo "$(BLUE)AnythingLLM Cloud Sync Makefile$(RESET)"
	@echo ""
	@echo "Available commands:"
	@echo "  $(GREEN)help$(RESET)              - Show this help message"
	@echo "  $(GREEN)deploy$(RESET)            - Deploy stack and sync environment to cloud"
	@echo "  $(GREEN)clean$(RESET)             - Clean up SSM parameters and delete stack"
	@echo ""
	@echo "Stack Management:"
	@echo "  $(GREEN)update-env$(RESET)        - Update environment variables and force ECS redeploy"
	@echo "  $(GREEN)describe-service$(RESET)  - Show ECS service status and recent events"
	@echo "  $(GREEN)deploy-stack$(RESET)      - Deploy CloudFormation stack only (for new stacks)"
	@echo "  $(GREEN)update-stack$(RESET)      - Update CloudFormation stack only (for existing stacks)"
	@echo "  $(GREEN)sync-env$(RESET)          - Sync environment variables to Parameter Store"
	@echo "  $(GREEN)delete-stack$(RESET)      - Delete CloudFormation stack"
	@echo ""
	@echo "Resource Cleanup:"
	@echo "  $(GREEN)clean-ssm$(RESET)         - Delete Parameter Store parameters"
	@echo ""
	@echo "Current Env Variables:"
	@echo "  STACK_NAME = $(STACK_NAME)"
	@echo "  REGION = $(REGION)"
	@echo "  VERBOSE = $(VERBOSE) (set to 'true' for verbose output)"
	@echo ""
	@echo "Note: AWS credentials should be set in your environment:"
	@echo "  export AWS_ACCESS_KEY_ID=your-access-key"
	@echo "  export AWS_SECRET_ACCESS_KEY=your-secret-key"
	@echo "  export AWS_SESSION_TOKEN=your-session-token  # If using temporary credentials"

check-image:
	@echo "$(BLUE)Checking if image exists in ECR...$(RESET)"
	@if ! aws ecr describe-images --repository-name $(STACK_NAME) --image-ids imageTag=latest --region $(REGION) > /dev/null 2>&1; then \
		echo "$(RED)Error: Image does not exist in ECR. Run 'make -f Makefile-img push-image' first or remove SKIP_IMAGE=true.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Image exists in ECR.$(RESET)"

deploy-stack: check-image
	@echo "$(BLUE)Checking CloudFormation stack status...$(RESET)"
	@if aws cloudformation describe-stacks --stack-name $(STACK_NAME) --region $(REGION) >/dev/null 2>&1; then \
		echo "$(YELLOW)Stack already exists. Use 'make delete-stack' first if you want to recreate it.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Deploying CloudFormation stack...$(RESET)"
	@cd deploy-aws && make deploy STACK_NAME=$(STACK_NAME) REGION=$(REGION)
	@echo "$(GREEN)Stack deployment complete!$(RESET)"

sync-env:
	@echo "$(BLUE)Syncing environment variables and configuration to cloud...$(RESET)"
	@cd deploy-aws/scripts && ./sync-env-to-parameter-store.sh --stack $(STACK_NAME)
	@echo "$(GREEN)Environment variables and configuration sync complete!$(RESET)"

update-stack:
	@echo "$(BLUE)Checking CloudFormation stack status...$(RESET)"
	@if ! aws cloudformation describe-stacks --stack-name $(STACK_NAME) --region $(REGION) >/dev/null 2>&1; then \
		echo "$(RED)Error: Stack '$(STACK_NAME)' does not exist. Use 'make deploy-stack' first.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Updating CloudFormation stack...$(RESET)"
	@cd deploy-aws && make update STACK_NAME=$(STACK_NAME) REGION=$(REGION)
	@echo "$(GREEN)Stack update complete!$(RESET)"

deploy: sync-env deploy-stack

update-env:
	@echo "$(BLUE)Checking CloudFormation stack status...$(RESET)"
	@if ! aws cloudformation describe-stacks --stack-name $(STACK_NAME) --region $(REGION) >/dev/null 2>&1; then \
		echo "$(RED)Error: Stack '$(STACK_NAME)' does not exist. Use 'make deploy' first.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Checking ECS service...$(RESET)"
	@if ! aws ecs describe-services --cluster $(STACK_NAME)-cluster --services $(STACK_NAME)-service --region $(REGION) >/dev/null 2>&1; then \
		echo "$(RED)Error: ECS service not found. Stack may not be properly deployed.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Syncing environment variables...$(RESET)"
	@$(MAKE) sync-env
	@echo "$(BLUE)Forcing ECS service update...$(RESET)"
	@aws ecs update-service \
		--cluster $(STACK_NAME)-cluster \
		--service $(STACK_NAME)-service \
		--force-new-deployment \
		--region $(REGION)
	@echo "$(GREEN)Service update initiated. New tasks will be created with updated environment variables.$(RESET)"
	@echo "$(BLUE)Monitoring deployment status...$(RESET)"
	@echo "$(BLUE)You can check the status using:$(RESET)"
	@echo "  make describe-service"
	@echo "$(BLUE)Or view logs using:$(RESET)"
	@echo "  aws logs tail /ecs/$(STACK_NAME) --follow"

describe-service:
	@echo "$(BLUE)Describing ECS service status...$(RESET)"
	@aws ecs describe-services \
		--cluster $(STACK_NAME)-cluster \
		--services $(STACK_NAME)-service \
		--region $(REGION) \
		--query 'services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount,Events:events[0:3]}' \
		--output table

delete-stack:
	@echo "$(RED)Deleting CloudFormation stack '$(STACK_NAME)'...$(RESET)"
	@if ! aws cloudformation describe-stacks --stack-name $(STACK_NAME) --region $(REGION) >/dev/null 2>&1; then \
		echo "$(YELLOW)Stack '$(STACK_NAME)' does not exist.$(RESET)"; \
		exit 0; \
	fi
	@read -p "Are you sure you want to delete stack '$(STACK_NAME)'? [y/N] " confirm && [[ $$confirm == [yY] || $$confirm == [yY][eE][sS] ]] || exit 1
	@aws cloudformation delete-stack --stack-name $(STACK_NAME) --region $(REGION)
	@echo "$(BLUE)Waiting for stack deletion to complete...$(RESET)"
	@aws cloudformation wait stack-delete-complete --stack-name $(STACK_NAME) --region $(REGION)
	@echo "$(GREEN)Stack deletion complete!$(RESET)"

clean-ssm:
	@echo "$(RED)Cleaning up Parameter Store parameters...$(RESET)"
	@cd deploy-aws/scripts && ./clean-cloud-resources.sh --stack $(STACK_NAME) --region $(REGION) --ssm-only

clean: clean-ssm delete-stack
