#!/bin/bash
# Generate secure random values for AnythingLLM secrets

# Function to generate a random string of specified length
generate_random_string() {
    local length=$1
    openssl rand -base64 $((length * 3/4)) | tr -dc 'a-zA-Z0-9' | head -c $length
}

# Function to print usage
print_usage() {
    echo "AnythingLLM Secrets Generator"
    echo ""
    echo "This script generates secure random values for AnythingLLM deployment."
    echo "The values will be output in CloudFormation parameters JSON format."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -o, --output   Specify output file (default: prints to stdout)"
    echo ""
    echo "Example:"
    echo "  $0 --output ../cloudformation/personal-parameters.json"
}

# Parse command line arguments
OUTPUT_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
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

# Generate secure random values
SIG_KEY=$(generate_random_string 32)
SIG_SALT=$(generate_random_string 32)
JWT_SECRET=$(generate_random_string 32)

# Create JSON output
JSON_CONTENT=$(cat << EOF
[
    {
        "ParameterKey": "OpenAiKey",
        "ParameterValue": "sk-replace-with-your-key"
    },
    {
        "ParameterKey": "SigKey",
        "ParameterValue": "$SIG_KEY"
    },
    {
        "ParameterKey": "SigSalt",
        "ParameterValue": "$SIG_SALT"
    },
    {
        "ParameterKey": "JwtSecret",
        "ParameterValue": "$JWT_SECRET"
    },
    {
        "ParameterKey": "VectorDb",
        "ParameterValue": "lancedb"
    },
    {
        "ParameterKey": "LlmProvider",
        "ParameterValue": "openai"
    },
    {
        "ParameterKey": "OpenModelPref",
        "ParameterValue": "gpt-4o"
    },
    {
        "ParameterKey": "ContainerCpu",
        "ParameterValue": "1024"
    },
    {
        "ParameterKey": "ContainerMemory",
        "ParameterValue": "2048"
    },
    {
        "ParameterKey": "VpcCidr",
        "ParameterValue": "10.0.0.0/16"
    },
    {
        "ParameterKey": "PublicSubnet1Cidr",
        "ParameterValue": "10.0.1.0/24"
    },
    {
        "ParameterKey": "PublicSubnet2Cidr",
        "ParameterValue": "10.0.2.0/24"
    }
]
EOF
)

# Output the results
if [ -n "$OUTPUT_FILE" ]; then
    echo "$JSON_CONTENT" > "$OUTPUT_FILE"
    chmod 600 "$OUTPUT_FILE"
    echo "Generated parameters saved to: $OUTPUT_FILE"
    echo "File permissions set to 600 (user read/write only)"
    echo ""
    echo "IMPORTANT:"
    echo "1. Replace 'sk-replace-with-your-key' with your actual OpenAI API key"
    echo "2. Keep this file secure and never commit it to version control"
else
    echo "$JSON_CONTENT"
fi

# Print the generated values to stderr for reference
echo "" >&2
echo "Generated secure random values:" >&2
echo "SIG_KEY: $SIG_KEY" >&2
echo "SIG_SALT: $SIG_SALT" >&2
echo "JWT_SECRET: $JWT_SECRET" >&2
echo "" >&2
echo "Make sure to keep these values secure and never commit them to version control." >&2
