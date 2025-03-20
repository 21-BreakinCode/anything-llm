#!/bin/bash
# Set up ECR repository and push AnythingLLM Docker image

# Function to print usage
print_usage() {
    echo "AnythingLLM ECR Setup Script"
    echo ""
    echo "This script creates an ECR repository and pushes the AnythingLLM Docker image."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -r, --region   AWS region (default: us-east-1)"
    echo "  -n, --name     Repository name (default: anythingllm)"
    echo ""
    echo "Example:"
    echo "  $0 --region us-west-2 --name my-anythingllm"
}

# Default values
REGION="us-east-1"
REPO_NAME="anythingllm"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -r|--region)
            REGION="$2"
            shift
            shift
            ;;
        -n|--name)
            REPO_NAME="$2"
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

echo "Setting up ECR repository in region $REGION..."

# Get AWS account ID
echo "Getting AWS account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get AWS account ID. Make sure AWS CLI is configured."
    exit 1
fi

# Create ECR repository if it doesn't exist
echo "Checking if ECR repository exists..."
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating ECR repository '$REPO_NAME'..."
    aws ecr create-repository \
        --repository-name $REPO_NAME \
        --region $REGION \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create ECR repository."
        exit 1
    fi
fi

# Log in to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
if [ $? -ne 0 ]; then
    echo "Error: Failed to log in to ECR."
    exit 1
fi

# Build Docker image if it doesn't exist locally
echo "Checking for local Docker image..."
if ! docker image inspect anythingllm:latest > /dev/null 2>&1; then
    echo "Building Docker image..."
    cd ../.. && docker build -t anythingllm:latest -f docker/Dockerfile .
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build Docker image."
        exit 1
    fi
fi

# Tag and push image
echo "Tagging image..."
docker tag anythingllm:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
if [ $? -ne 0 ]; then
    echo "Error: Failed to tag image."
    exit 1
fi

echo "Pushing image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
if [ $? -ne 0 ]; then
    echo "Error: Failed to push image to ECR."
    exit 1
fi

# Create image digest file for reference
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest)
echo "Image successfully pushed to ECR"
echo "Repository: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"
echo "Tag: latest"
echo "Digest: $DIGEST"

# Save repository URL to a file for reference
echo "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME" > "$(dirname "$0")/../cloudformation/ecr-repository-url.txt"
echo "Repository URL saved to: $(dirname "$0")/../cloudformation/ecr-repository-url.txt"

echo ""
echo "ECR setup complete! You can now use this image in your CloudFormation template."
echo "Repository URL: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"
