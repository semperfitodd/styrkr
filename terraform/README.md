# Styrkr Infrastructure

Production-ready Terraform configuration for the Styrkr storytelling application.

## Architecture

- **API Gateway**: HTTP API with JWT authorization via Cognito
- **Lambda Functions**: Three microservices (profiles, stories, child_stories)
- **DynamoDB**: Four tables (users, profiles, stories, story_nodes)
- **Cognito**: User authentication with Apple and Google OAuth
- **CloudFront + S3**: Static website hosting
- **Route53**: DNS management

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Node.js 20.x (for Lambda builds)
- Valid Route53 hosted zone

## Setup

1. Create `terraform.tfvars` with your configuration:
```hcl
project = "styrkr-dev"
app_name = "styrkr"
domain = "example.com"
region = "us-east-1"

apple_app_id = "com.example.styrkr"
apple_key_id = "ABC123"
apple_private_key = "base64-encoded-key"
apple_team_id = "TEAM123"

google_client_id = "your-client-id"
google_client_secret = "your-client-secret"
```

2. Initialize Terraform:
```bash
terraform init
```

3. Plan and apply:
```bash
terraform plan
terraform apply
```

## Lambda Functions

### Shared Layer
- Common utilities for DynamoDB access
- JWT token parsing
- Response formatting

### Profiles Lambda
Handles child profile management:
- `GET /me` - Get current user
- `GET /profiles` - List all profiles
- `POST /profiles` - Create profile
- `PUT /profiles/{profileId}` - Update profile
- `DELETE /profiles/{profileId}` - Delete profile

### Stories Lambda
Manages stories and story nodes:
- `GET /stories` - List stories by profile
- `POST /stories` - Create story
- `GET /stories/{storyId}` - Get story details
- `PUT /stories/{storyId}` - Update story
- `DELETE /stories/{storyId}` - Delete story
- `GET /stories/{storyId}/nodes` - List story nodes
- `POST /stories/{storyId}/nodes` - Create node
- `GET /stories/{storyId}/nodes/{nodeId}` - Get node
- `PUT /stories/{storyId}/nodes/{nodeId}` - Update node

### Child Stories Lambda
Child-friendly story creation:
- `POST /stories/child` - Create child story with initial node
- `POST /stories/{storyId}/continue` - Continue story with choice

## Security

- All secrets stored in terraform.tfvars or AWS Secrets Manager
- No hardcoded credentials in code
- DynamoDB encryption at rest
- S3 encryption enabled
- Point-in-time recovery enabled for all tables
- CloudWatch logs with 7-day retention

## Development

Lambda functions use TypeScript with strict mode enabled. The shared layer provides common utilities to keep code DRY.

To test locally:
```bash
cd lambda_profiles
npm install
npm run build
```

## Outputs

After applying, Terraform outputs:
- `api_url` - API Gateway custom domain
- `frontend_url` - CloudFront website URL
- `cognito_user_pool_id` - Cognito User Pool ID
- `cognito_client_id` - Cognito Client ID
- `cognito_domain` - Cognito custom domain
- `oauth_secrets_arn` - Secrets Manager ARN