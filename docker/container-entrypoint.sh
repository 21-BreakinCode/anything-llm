#!/bin/bash
# container-entrypoint.sh
# Loads environment variables from Parameter Store

# STACK_NAME is passed as an environment variable in the task definition
STACK_NAME=${STACK_NAME:-anythingllm}
PARAM_PATH="/$STACK_NAME/anythingllm/env"

echo "Loading environment variables from Parameter Store path: $PARAM_PATH..."

echo "Debug: Parameter Store path is $PARAM_PATH/.env"

# Get the .env file content from Parameter Store
echo "Debug: Fetching parameter from AWS Parameter Store..."
parameter_result=$(aws ssm get-parameter \
    --name "$PARAM_PATH/.env" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text 2>&1)
aws_exit_code=$?

if [ $aws_exit_code -eq 0 ]; then
    echo "Debug: Successfully retrieved parameter from AWS"

    # Write the content to .env file
    echo "Debug: Writing content to /app/server/.env"
    echo "$parameter_result" > /app/server/.env
    echo "Debug: Environment file written successfully!"

    echo "Debug: Content of /app/server/.env (first line only):"
    head -n 1 /app/server/.env | sed 's/\(.*\=\).*/\1****/'  # Show key but hide value

    # Source the .env file to set environment variables
    echo "Debug: Processing environment variables..."
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        if [[ $line =~ ^#.*$ ]] || [[ -z $line ]]; then
            echo "Debug: Skipping comment or empty line"
            continue
        fi

        # Extract key and value, handling quotes properly
        if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            # Trim whitespace
            key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

            # Remove surrounding quotes if present
            value=$(echo "$value" | sed -e 's/^["\x27]//' -e 's/["\x27]$//')

            if [ -n "$key" ]; then
                export "$key=$value"
                echo "Debug: Exported $key=****"
            else
                echo "Debug: Invalid line format: $line"
            fi
        else
            echo "Debug: Could not parse line: $line"
        fi
    done < /app/server/.env
    echo "Debug: Finished processing environment variables"

    # Verify some key environment variables (without showing values)
    echo "Debug: Verifying key environment variables..."
    for var in "STORAGE_DIR" "SERVER_PORT" "VECTOR_DB" "LLM_PROVIDER"; do
        if [ -n "${!var}" ]; then
            echo "Debug: $var is set"
        else
            echo "Warning: $var is not set"
        fi
    done
else
    echo "Error: Failed to load .env from Parameter Store. Exit code: $aws_exit_code"
    echo "Error details: $parameter_result"
    echo "Warning: Using existing environment variables."
fi

echo "Debug: Container entrypoint script completed"

# Start the application
exec "$@"
