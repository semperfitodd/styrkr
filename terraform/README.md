# Styrkr Infrastructure

Production-ready Terraform configuration for the STYRKR strength training application.

## Architecture

- **API Gateway**: HTTP API with JWT authorization via Cognito
- **Lambda Functions**: Microservices for workout generation, logging, and profile management
- **DynamoDB**: Two tables - user data (main) and app config (exercise library)
- **Cognito**: User authentication with Apple and Google OAuth
- **CloudFront + S3**: Static website hosting + public exercise library JSON
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

### Profile Lambda
- `GET /profile` - Get user profile
- `PUT /profile` - Update profile (training days, units, constraints, capabilities)

### Strength Lambda
- `GET /strength` - Get strength data (1RMs, training maxes)
- `PUT /strength` - Update strength data

### Library Publisher Lambda
- `POST /admin/library/publish` - Generate exercise library snapshot to S3 (JWT required)
- Reads exercises from DynamoDB, creates versioned + latest JSON files
- Publishes to S3 with CloudFront cache headers

## Security

- All secrets stored in terraform.tfvars or AWS Secrets Manager
- No hardcoded credentials in code
- DynamoDB encryption at rest
- S3 encryption enabled
- Point-in-time recovery enabled for all tables
- CloudWatch logs with 7-day retention

## Exercise Library

120+ exercises for 5/3/1 Krypteia + longevity program stored in DynamoDB and auto-published to CloudFront.

### Seed Exercises
```bash
cd scripts
export CONFIG_TABLE_NAME=styrkr_app_config
./seed_exercise_library.sh
```

Library automatically publishes to S3 within 30 seconds of any DynamoDB changes via DynamoDB Streams.

### Manual Publish (Optional)
```bash
curl -X POST https://dev-api.yourdomain.com/admin/library/publish \
  -H "Authorization: Bearer $JWT_TOKEN"
```

### Access Library
- Latest: `https://dev.yourdomain.com/config/exercises.latest.json`
- Versioned: `https://dev.yourdomain.com/config/exercises.v{N}.json`

**Auto-publish:** DynamoDB Stream triggers publish on INSERT/MODIFY/REMOVE with 30s debounce.  
**Manual publish:** Available for immediate updates (bypasses debounce).

## Outputs

After applying, Terraform outputs:
- `api_url` - API Gateway custom domain
- `frontend_url` - CloudFront website URL
- `library_latest_url` - Exercise library CloudFront URL
- `config_bucket_name` - S3 bucket for config snapshots
- `config_table_name` - DynamoDB table for exercises
- `cognito_user_pool_id` - Cognito User Pool ID
- `cognito_client_id` - Cognito Client ID
- `cognito_domain` - Cognito custom domain