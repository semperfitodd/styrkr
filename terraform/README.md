# Styrkr Infrastructure

Production-ready Terraform configuration for the STYRKR strength training application.

## Architecture

- **API Gateway**: HTTP API with JWT authorization via Cognito
- **Lambda Functions**: Microservices for profile and strength data management
- **DynamoDB**: Single table for user data (profile, strength, workouts)
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

## Security

- All secrets stored in terraform.tfvars or AWS Secrets Manager
- No hardcoded credentials in code
- DynamoDB encryption at rest
- S3 encryption enabled
- Point-in-time recovery enabled for all tables
- CloudWatch logs with 7-day retention

## Exercise Library

61 exercises for 5/3/1 Krypteia + longevity program stored as a static JSON file in S3.

### Access Library
The exercise library is publicly accessible via CloudFront:
- URL: `https://dev.yourdomain.com/config/exercises.latest.json`

The JSON file is stored in the S3 config bucket at `config/exercises.latest.json` and served through CloudFront with caching enabled.

## Outputs

After applying, Terraform outputs:
- `api_url` - API Gateway custom domain
- `frontend_url` - CloudFront website URL
- `library_latest_url` - Exercise library CloudFront URL
- `config_bucket_name` - S3 bucket for config files (exercise library JSON)
- `cognito_user_pool_id` - Cognito User Pool ID
- `cognito_client_id` - Cognito Client ID
- `cognito_domain` - Cognito custom domain