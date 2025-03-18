# AnythingLLM Customizations

This directory contains various customization options and deployment templates for AnythingLLM.

## Available Customizations

### AWS with Cloudflare Integration
Location: [`aws/cloudformation/cloudflare-integrated/`](aws/cloudformation/cloudflare-integrated/)

Deploy AnythingLLM on AWS with Cloudflare integration for enhanced security and performance:
- Private EC2 instance deployment
- Cloudflare proxy integration
- Automated security group management
- SSL/TLS encryption
- DDoS protection

Features:
- CloudFormation template for infrastructure deployment
- Parameter templates for easy configuration
- Automatic Cloudflare IP range updates
- Comprehensive security controls
- Detailed deployment instructions

To get started with AWS + Cloudflare deployment:
1. Navigate to the [`aws/cloudformation/cloudflare-integrated/`](aws/cloudformation/cloudflare-integrated/) directory
2. Follow the instructions in the README.md file
3. Use the provided scripts and templates for deployment

## Directory Structure

```
customize/
├── README.md
└── aws/
    └── cloudformation/
        └── cloudflare-integrated/
            ├── README.md
            ├── template.yaml
            ├── parameters.json
            └── scripts/
                └── update-cf-ips.sh
```

## Contributing

To add new customizations:
1. Create a new directory with a descriptive name
2. Include a README.md with detailed instructions
3. Provide necessary templates and scripts
4. Update this main README.md with the new customization

## Support

For issues or questions:
- AnythingLLM: [Official Repository](https://github.com/Mintplex-Labs/anything-llm)
- AWS Deployment: See AWS-specific README in the cloudformation directory
- Cloudflare Integration: See Cloudflare-specific documentation in the respective deployment guides
