# AnythingLLM with Cloudflare Integration

This CloudFormation template deploys AnythingLLM in a secure configuration with Cloudflare integration. The setup includes a private EC2 instance that's only accessible through Cloudflare's proxy.

## Prerequisites

1. AWS Account with appropriate permissions
2. Cloudflare account with:
   - A registered domain
   - Zone ID for your domain
   - API token with Zone.DNS permissions

## Quick Start

1. Copy `parameters.json` and update the values:
   ```json
   {
     "ParameterKey": "KeyName",
     "ParameterValue": "your-key-pair-name"  // Your EC2 key pair
   }
   ```

2. Deploy the stack:
   ```bash
   aws cloudformation create-stack \
     --stack-name anythingllm-cloudflare \
     --template-body file://template.yaml \
     --parameters file://parameters.json \
     --capabilities CAPABILITY_IAM
   ```

3. After deployment, follow the Cloudflare setup instructions in the stack outputs.

## Security Features

- EC2 instance in private subnet
- Security group restricted to Cloudflare IPs
- HTTPS encryption with Cloudflare SSL
- No direct public access to the instance

## Parameters

### Instance Configuration
- `InstanceType`: EC2 instance size (default: m6a.large)
  - Available AMD options:
    - m6a.large: 2 vCPU, 8 GiB RAM (recommended for most deployments)
    - m6a.xlarge: 4 vCPU, 16 GiB RAM (for higher workloads)
    - m6a.2xlarge: 8 vCPU, 32 GiB RAM (for intensive workloads)
  - Fallback options:
    - t3.small, t3.medium, t3.large (if AMD instances are not required)
  - The m6a series features AMD EPYC processors, offering better price-performance ratio
- `InstanceVolume`: EBS volume size in GB (default: 10)
- `KeyName`: EC2 key pair for SSH access

### Network Configuration
- `VpcId`: Your VPC ID
- `PrivateSubnet`: Private subnet ID
- `AllowedCloudflareIPs`: Cloudflare IP ranges (pre-configured)

### Application Configuration
- `DomainName`: Your domain (e.g., llm.example.com)
- `CloudflareZoneId`: Your Cloudflare Zone ID
- `CloudflareAPIToken`: Cloudflare API token

## Architecture

```
Internet → Cloudflare Proxy → Private EC2 (AnythingLLM)
```

The EC2 instance runs in a private subnet and is only accessible through Cloudflare's proxy service, providing:
- DDoS protection
- Web Application Firewall
- SSL/TLS encryption
- Access control

## Maintenance

### Updating Cloudflare IPs

Cloudflare publishes their IP ranges at: https://www.cloudflare.com/ips/

The template includes a Makefile to help manage the stack and keep Cloudflare IP ranges updated:

```bash
# Show available commands
make help

# Update Cloudflare IPs and update the stack
make update-stack STACK_NAME=your-stack-name

# Only update Cloudflare IPs in parameters.json
make update-cf-ips

# Check required dependencies
make check-deps
```

The Makefile will:
1. Check for required dependencies (jq, curl, aws)
2. Fetch the latest Cloudflare IP ranges
3. Update the parameters.json file
4. Optionally update the CloudFormation stack

### Accessing the Instance

SSH access is available through the AWS Systems Manager Session Manager or by using a bastion host in your VPC.

## Troubleshooting

1. **Cannot access the application**
   - Verify Cloudflare DNS settings
   - Check security group rules
   - Confirm instance is running
   - Check instance logs: `docker logs $(docker ps -q)`

2. **SSL/TLS Issues**
   - Ensure Cloudflare SSL/TLS mode is set to "Full"
   - Verify SSL certificate is valid
   - Check Cloudflare page rules

3. **Performance Issues**
   - Consider upgrading instance type
   - Check EBS volume usage
   - Review Cloudflare caching settings

## Support

For issues related to:
- AnythingLLM: [Official Repository](https://github.com/Mintplex-Labs/anything-llm)
- Cloudflare: [Cloudflare Support](https://support.cloudflare.com)
- AWS: [AWS Support](https://aws.amazon.com/support)
