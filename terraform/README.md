# Styrkr Infrastructure

Production-ready Terraform configuration for the STYRKR strength training application.

## Architecture

- **API Gateway**: HTTP API with JWT authorization via Cognito
- **Lambda Functions**: Microservices for workout generation, logging, and profile management
- **DynamoDB**: Single-table design for users, plans, logs, and exercises
- **Cognito**: User authentication with Apple and Google OAuth
- **CloudFront + S3**: Static website hosting for React app
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
- e1RM calculations
- Response formatting

### Profiles Lambda
Handles user profile and training max management:
- `GET /me` - Get current user
- `GET /profile` - Get user profile with 1RMs
- `PUT /profile` - Update profile
- `POST /profile/1rm` - Update training maxes

### Workouts Lambda
Generates and manages workouts:
- `GET /plans` - List user's training plans
- `POST /plans` - Create new plan from template
- `GET /plans/:id/weeks/:week` - Get workout for week N (rendered on-demand)
- `POST /plans/:id/overrides` - Create override (swap accessory, move day)
- `DELETE /plans/:id/overrides/:overrideId` - Remove override

### Logs Lambda
Workout logging and analytics:
- `GET /logs` - List workout logs (paginated)
- `POST /logs` - Submit completed workout
- `GET /logs/:id` - Get log details
- `GET /analytics/e1rm` - Get e1RM trend data

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