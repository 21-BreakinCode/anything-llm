#!/bin/bash
# clean-cloud-resources.sh
# Deletes all cloud resources created for AnythingLLM

# Function to print usage
print_usage() {
    echo "AnythingLLM Cloud Resources Cleanup Script"
    echo ""
    echo "This script deletes all cloud resources created for AnythingLLM."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -s, --stack    Stack name (default: anythingllm)"
    echo "  -r, --region   AWS region (default: us-east-1)"
    echo "  -v, --verbose  Show verbose output"
    echo "  --ssm-only     Only clean up Parameter Store parameters"
    echo "  --s3-only      Only show S3 bucket cleanup instructions"
    echo "  --ecr-only     Only clean up ECR repository"
    echo ""
    echo "Example:"
    echo "  $0 --stack my-stack --region us-east-1"
    echo ""
    echo "Note: AWS credentials should be set in your environment"
}

# Default values
STACK_NAME="anythingllm"
REGION="us-east-1"
VERBOSE=false
SSM_ONLY=false
S3_ONLY=false
ECR_ONLY=false

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
        -r|--region)
            REGION="$2"
            shift
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --ssm-only)
            SSM_ONLY=true
            shift
            ;;
        --s3-only)
            S3_ONLY=true
            shift
            ;;
        --ecr-only)
            ECR_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Set AWS_PAGER to prevent command hanging
export AWS_PAGER=""

# Function for verbose logging
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "[DEBUG] $1"
    fi
}

# Function to check if we should proceed
confirm() {
    read -p "Are you sure you want to delete cloud resources for stack '$STACK_NAME'? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get AWS account ID
echo "Getting AWS account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get AWS account ID. Make sure AWS credentials are properly set."
    exit 1
fi

# Ask for confirmation unless doing single resource cleanup
if [ "$SSM_ONLY" = false ] && [ "$S3_ONLY" = false ] && [ "$ECR_ONLY" = false ]; then
    if ! confirm; then
        echo "Operation cancelled."
        exit 0
    fi
fi

echo "Starting cleanup for stack: $STACK_NAME"

# Function to clean up Parameter Store parameters
cleanup_ssm() {
    echo "Checking for Parameter Store parameters..."

    # First, try to list all parameters to help with debugging
    if [ "$VERBOSE" = true ]; then
        echo "[DEBUG] Listing all parameters under /$STACK_NAME..."
        aws ssm get-parameters-by-path \
            --path "/$STACK_NAME" \
            --recursive \
            --query "Parameters[*].[Name]" \
            --output text \
            --region $REGION
    fi

    # Try both path formats
    PATHS=("/$STACK_NAME/anythingllm/env" "/$STACK_NAME/env")
    for PATH_PREFIX in "${PATHS[@]}"; do
        log_verbose "Checking path: $PATH_PREFIX"
        PARAMS=$(aws ssm get-parameters-by-path \
            --path "$PATH_PREFIX" \
            --recursive \
            --query "Parameters[*].[Name]" \
            --output text \
            --region $REGION 2>/dev/null)

        if [ $? -eq 0 ] && [ ! -z "$PARAMS" ]; then
            echo "Found parameters under $PATH_PREFIX"
            echo "$PARAMS" | while read -r param; do
                echo "Deleting parameter: $param"
                aws ssm delete-parameter \
                    --name "$param" \
                    --region $REGION
                if [ $? -eq 0 ]; then
                    echo "Deleted parameter: $param"
                else
                    echo "Failed to delete parameter: $param"
                fi
            done
        else
            log_verbose "No parameters found under $PATH_PREFIX"
        fi
    done
}

# Function to show S3 bucket information
show_s3_info() {
    S3_BUCKET="${STACK_NAME}-config"
    echo "Checking S3 bucket: $S3_BUCKET"
    if aws s3api head-bucket --bucket $S3_BUCKET 2>/dev/null; then
        echo "Found S3 bucket: $S3_BUCKET"

        # Check if bucket has versioning enabled
        VERSIONING=$(aws s3api get-bucket-versioning \
            --bucket $S3_BUCKET \
            --region $REGION \
            --query 'Status' \
            --output text 2>/dev/null)

        # List bucket contents
        echo "Current bucket contents:"
        aws s3 ls s3://$S3_BUCKET --recursive

        echo ""
        echo "⚠️  IMPORTANT: S3 Bucket Information ⚠️"
        echo "Bucket name: $S3_BUCKET"
        echo "Versioning: ${VERSIONING:-Disabled}"
        echo ""
        echo "To manually delete this bucket and its contents:"
        echo "1. Empty the bucket:"
        echo "   aws s3 rm s3://$S3_BUCKET --recursive"
        if [ "$VERSIONING" = "Enabled" ]; then
            echo "2. Delete all versions and delete markers:"
            echo "   aws s3api delete-objects --bucket $S3_BUCKET --delete \"\$(aws s3api list-object-versions --bucket $S3_BUCKET --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')\""
            echo "   aws s3api delete-objects --bucket $S3_BUCKET --delete \"\$(aws s3api list-object-versions --bucket $S3_BUCKET --output=json --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')\""
        fi
        echo "3. Delete the bucket:"
        echo "   aws s3api delete-bucket --bucket $S3_BUCKET --region $REGION"
        echo ""
        echo "Note: The bucket will be automatically deleted when you delete the CloudFormation stack."
    else
        echo "S3 bucket not found or not accessible: $S3_BUCKET"
    fi
}

# Function to clean up ECR repository
cleanup_ecr() {
    REPO_NAME="anythingllm"
    echo "Checking for ECR repository: $REPO_NAME"
    if aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION 2>/dev/null; then
        echo "Deleting ECR repository..."
        aws ecr delete-repository \
            --repository-name $REPO_NAME \
            --force \
            --region $REGION
        if [ $? -eq 0 ]; then
            echo "ECR repository deleted successfully."
        else
            echo "Failed to delete ECR repository."
        fi
    else
        echo "ECR repository not found."
    fi
}

# Execute cleanup based on flags
if [ "$SSM_ONLY" = true ]; then
    cleanup_ssm
elif [ "$S3_ONLY" = true ]; then
    show_s3_info
elif [ "$ECR_ONLY" = true ]; then
    cleanup_ecr
else
    cleanup_ssm
    show_s3_info
    cleanup_ecr
fi

echo "Cloud resources cleanup completed!"
