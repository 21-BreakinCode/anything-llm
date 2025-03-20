#!/bin/bash
# Validate AnythingLLM AWS deployment

# Function to print usage
print_usage() {
    echo "AnythingLLM Deployment Validator"
    echo ""
    echo "This script validates the AnythingLLM deployment on AWS."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -s, --stack    Stack name (default: anythingllm)"
    echo "  -r, --region   AWS region (default: us-east-1)"
    echo ""
    echo "Example:"
    echo "  $0 --stack my-anythingllm --region us-west-2"
}

# Default values
STACK_NAME="anythingllm"
REGION="us-east-1"

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
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

echo "Validating deployment of stack '$STACK_NAME' in region '$REGION'..."

# Check if stack exists
echo "Checking if stack exists..."
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Error: Stack '$STACK_NAME' does not exist in region '$REGION'."
    exit 1
fi

echo "Stack status: $STACK_STATUS"

# Check if stack is in a good state
case $STACK_STATUS in
    CREATE_COMPLETE|UPDATE_COMPLETE)
        echo "Stack is in a completed state."
        ;;
    CREATE_IN_PROGRESS|UPDATE_IN_PROGRESS|UPDATE_COMPLETE_CLEANUP_IN_PROGRESS)
        echo "Stack is still being created/updated. Please wait and try again later."
        exit 1
        ;;
    *)
        echo "Warning: Stack is in an unexpected state: $STACK_STATUS"
        ;;
esac

# Get stack outputs
echo -e "\nRetrieving stack outputs..."
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[]' \
    --output table

# Get load balancer URL
echo -e "\nGetting load balancer URL..."
LB_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query "Stacks[0].Outputs[?OutputKey=='AnythingLLMURL'].OutputValue" \
    --output text)

if [ -z "$LB_URL" ]; then
    echo "Error: Could not retrieve load balancer URL from stack outputs."
    exit 1
fi

echo "AnythingLLM URL: $LB_URL"

# Check ECS service status
echo -e "\nChecking ECS service status..."
CLUSTER_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query "Stacks[0].Outputs[?OutputKey=='ECSClusterName'].OutputValue" \
    --output text)

SERVICE_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query "Stacks[0].Outputs[?OutputKey=='ECSServiceName'].OutputValue" \
    --output text)

if [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    echo "Error: Could not retrieve cluster or service name from stack outputs."
    exit 1
fi

echo "ECS Cluster: $CLUSTER_NAME"
echo "ECS Service: $SERVICE_NAME"

# Get service details
SERVICE_STATUS=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $REGION \
    --query 'services[0].status' \
    --output text)

echo "Service status: $SERVICE_STATUS"

DESIRED_COUNT=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $REGION \
    --query 'services[0].desiredCount' \
    --output text)

RUNNING_COUNT=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $REGION \
    --query 'services[0].runningCount' \
    --output text)

echo "Desired tasks: $DESIRED_COUNT"
echo "Running tasks: $RUNNING_COUNT"

if [ "$RUNNING_COUNT" -lt "$DESIRED_COUNT" ]; then
    echo "Warning: Not all desired tasks are running."
fi

# Check EFS status
echo -e "\nChecking EFS status..."
EFS_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query "Stacks[0].Outputs[?OutputKey=='EFSFileSystemId'].OutputValue" \
    --output text)

if [ -n "$EFS_ID" ]; then
    EFS_STATUS=$(aws efs describe-file-systems \
        --file-system-id $EFS_ID \
        --region $REGION \
        --query 'FileSystems[0].LifeCycleState' \
        --output text)

    echo "EFS File System ID: $EFS_ID"
    echo "EFS Status: $EFS_STATUS"
else
    echo "Warning: Could not retrieve EFS ID from stack outputs."
fi

# Test endpoint
echo -e "\nTesting endpoint accessibility..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $LB_URL)
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to endpoint."
    exit 1
fi

echo "Endpoint HTTP response code: $HTTP_CODE"

# Print summary
echo -e "\nDeployment Validation Summary:"
echo "--------------------------------"
echo "Stack Status: $STACK_STATUS"
echo "Service Status: $SERVICE_STATUS"
echo "Tasks: $RUNNING_COUNT/$DESIRED_COUNT running"
echo "EFS Status: $EFS_STATUS"
echo "Endpoint Status: HTTP $HTTP_CODE"
echo "Application URL: $LB_URL"

# Final status
if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ] && \
   [ "$SERVICE_STATUS" = "ACTIVE" ] && \
   [ "$RUNNING_COUNT" -eq "$DESIRED_COUNT" ] && \
   [ "$EFS_STATUS" = "available" ] && \
   [ "$HTTP_CODE" = "200" ]; then
    echo -e "\n✅ Deployment validation successful!"
    exit 0
else
    echo -e "\n⚠️  Deployment validation completed with warnings."
    exit 1
fi
