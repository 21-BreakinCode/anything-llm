#!/bin/bash
# sync-env-to-parameter-store.sh
# Syncs all environment variables from .env to Parameter Store

# Function to print usage
print_usage() {
    echo "AnythingLLM Cloud Sync Script"
    echo ""
    echo "This script syncs environment variables from .env to Parameter Store."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -s, --stack    Stack name (default: anythingllm)"
    echo ""
    echo "Example:"
    echo "  $0 --stack my-stack"
    echo ""
    echo "Note: AWS credentials should be set in your environment"
}

# Default values
STACK_NAME="anythingllm"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -s|--stack)
            STACK_NAME="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

ENV_FILE="../../docker/.env"
PARAM_PATH="/$STACK_NAME/anythingllm/env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found"
    exit 1
fi

echo "Syncing environment variables to Parameter Store under path $PARAM_PATH..."

# Read entire .env file content
env_content=$(cat "$ENV_FILE")

# Store as SecureString since it may contain sensitive information
param_type="SecureString"

echo "Setting parameter $PARAM_PATH/.env as $param_type..."
aws ssm put-parameter \
    --name "$PARAM_PATH/.env" \
    --value "$env_content" \
    --type "$param_type" \
    --overwrite

echo "Environment variables successfully synced to Parameter Store!"
