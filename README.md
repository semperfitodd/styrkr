# Styrkr

A serverless strength training platform that generates 5/3/1 Krypteia-based workouts with intelligent program management, mobility tracking, and flexible scheduling. Built for iOS with a web companion interface.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Key Concepts](#key-concepts)
  - [Program Template vs Plan Instance](#program-template-vs-plan-instance)
  - [Week Rendering](#week-rendering)
  - [Overrides](#overrides)
  - [Workout Logs](#workout-logs)
  - [Exercise Library](#exercise-library)
  - [Mobility Scorecard](#mobility-scorecard)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
  - [Frontend (React Web)](#frontend-react-web)
  - [Backend (Lambda + API Gateway)](#backend-lambda--api-gateway)
  - [Mobile (iOS + watchOS)](#mobile-ios--watchos)
- [Deployment](#deployment)
  - [Initial Setup](#initial-setup)
  - [Deploy Infrastructure](#deploy-infrastructure)
  - [Deploy Frontend](#deploy-frontend)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [AWS Profile](#aws-profile)
  - [Cognito Setup](#cognito-setup)
- [API Overview](#api-overview)
- [Folder Structure](#folder-structure)
- [Testing & Linting](#testing--linting)
- [Roadmap](#roadmap)
- [Security](#security)
- [License](#license)

---

## Overview

Styrkr generates strength training workouts based on user-provided 1RMs (squat, bench, deadlift, overhead press) using the 5/3/1 Krypteia methodology. Users can view workouts arbitrarily far into the future, adjust training schedules within a "floating week" to accommodate travel, swap accessory movements within constraints, and track mobility work with hip-focused assessments.

The system uses a single-table DynamoDB design for user profiles, workout plans, logs, and exercise libraries. Workouts are rendered on-demand rather than pre-generated, enabling flexible scheduling and real-time plan adjustments.

---

## Architecture

```
┌─────────────────┐
│   iOS App       │
│ (iPhone + Watch)│
└────────┬────────┘
         │
         │ HTTPS + JWT
         │
┌────────▼────────────────────────────────────────┐
│              CloudFront + S3                    │
│         (React SPA - Web Interface)             │
└────────┬────────────────────────────────────────┘
         │
         │ HTTPS + JWT
         │
┌────────▼────────────────────────────────────────┐
│          API Gateway (HTTP API)                 │
│           + Cognito JWT Authorizer              │
└────────┬────────────────────────────────────────┘
         │
         │ Invokes
         │
┌────────▼────────────────────────────────────────┐
│         Lambda Functions (Node.js/TS)           │
│  - Profile Management                           │
│  - Workout Generation                           │
│  - Log Recording                                │
│  - Exercise Library CRUD                        │
│  - Mobility Tracking                            │
└────────┬────────────────────────────────────────┘
         │
         │ Read/Write
         │
┌────────▼────────────────────────────────────────┐
│         DynamoDB (Single Table)                 │
│  PK: USER#<id> | PLAN#<id> | EXERCISE#<id>     │
│  SK: PROFILE | WEEK#<n> | LOG#<date>           │
└─────────────────────────────────────────────────┘
```

**Key Flows:**
- **Authentication:** Cognito User Pools with optional Apple/Google federation
- **Workout Generation:** Lambda computes workout for week N on-demand based on plan template + overrides
- **Logging:** User submits completed sets; Lambda writes to DynamoDB and updates e1RM calculations
- **Mobility:** Separate scorecard entity tracks hip mobility tests and progress over time

---

## Tech Stack

| Layer         | Technology                          |
|---------------|-------------------------------------|
| **Frontend**  | React 19, React Scripts 5           |
| **Mobile**    | SwiftUI (iOS 18+, watchOS)          |
| **Backend**   | AWS Lambda (Node.js 20, TypeScript) |
| **API**       | API Gateway HTTP API                |
| **Auth**      | AWS Cognito (User Pools + Identity) |
| **Database**  | DynamoDB (single-table design)      |
| **CDN**       | CloudFront + S3                     |
| **IaC**       | Terraform 1.0+, AWS Provider 6.6    |

---

## Key Concepts

### Program Template vs Plan Instance

- **Program Template:** A reusable definition of a training cycle (e.g., "5/3/1 Krypteia 12-week"). Defines exercise selection, set/rep schemes, progression rules, and accessory constraints.
- **Plan Instance:** A user-specific instantiation of a template, anchored to a start date and seeded with the user's 1RMs. The plan instance tracks overrides, completed logs, and current training maxes.

### Week Rendering

Workouts are **not** pre-generated. Instead:
1. Client requests week N for a given plan
2. Lambda retrieves plan instance + template
3. Lambda applies progression formula to compute weights/reps for week N
4. Lambda applies any user overrides (swapped accessories, moved days)
5. Lambda returns computed workout JSON

This approach enables infinite forward planning and dynamic adjustments without data migration.

### Overrides

Users can modify workouts within constraints:
- **Day Swapping:** Move a workout to a different day within the same week (e.g., Monday → Wednesday)
- **Accessory Swaps:** Replace an accessory exercise with another matching the same tags (e.g., swap "goblet squat" for "Bulgarian split squat" if both tagged `#unilateral #quad-dominant`)
- **Deload Weeks:** Mark a week as deload to reduce intensity

Overrides are stored separately and merged during week rendering.

### Workout Logs

After completing a workout, the user submits:
- Exercise name
- Sets × reps × weight
- RPE (optional)
- Notes (optional)

Lambda:
1. Writes log entry to DynamoDB (`USER#<id>#LOG#<date>`)
2. Calculates estimated 1RM (e1RM) using Epley or Brzycki formula
3. Updates rolling e1RM trend for analytics
4. Marks workout as complete for progress tracking

### Exercise Library

Each user has a customizable exercise library:
- **Default Library:** Seeded on signup with standard movements
- **Custom Exercises:** Users can add/remove exercises in settings
- **Tags:** Exercises tagged by pattern (e.g., `#squat-pattern`), intent (`#strength`, `#hypertrophy`), equipment (`#barbell`, `#dumbbell`), and constraints (`#unilateral`, `#bodyweight`)
- **Substitution Logic:** Accessory swaps require matching tags to preserve training stimulus

### Mobility Scorecard

Tracks practical hip mobility tests:
- **Tests:** Hip flexor length, internal/external rotation, squat depth, single-leg balance
- **Scoring:** Pass/fail or numeric (e.g., degrees of rotation)
- **Frequency:** Assessed every 4 weeks
- **Integration:** Mobility work prescribed on non-Pilates days; scorecard progress displayed in analytics

---

## Prerequisites

- **Node.js:** 18+ (for Lambda development and React)
- **npm:** 9+ (or yarn/pnpm)
- **Terraform:** 1.0+
- **AWS CLI:** 2.x, configured with appropriate profile
- **Xcode:** 15+ (for iOS development)
- **AWS Account:** With Route53 hosted zone for custom domain

---

## Local Development

### Frontend (React Web)

```bash
cd static_site
npm install
npm start
```

The React app runs on `http://localhost:3000` by default. Configure API endpoint in environment variables (see [Configuration](#configuration)).

**Build for production:**
```bash
npm run build
```

Output is written to `static_site/build/` and deployed to S3 via Terraform.

### Backend (Lambda + API Gateway)

Lambda functions are written in TypeScript and deployed via Terraform. For local testing:

```bash
cd terraform/lambda_profiles  # or lambda_temp for temp function
npm install
npm run build
```

**TODO:** Add local Lambda testing with SAM or `lambda-local`. For now, deploy to AWS and test via API Gateway.

**Shared utilities:**
- Located in `terraform/lambda_shared/nodejs/utils.ts`
- Packaged as Lambda layer
- Includes DynamoDB helpers, auth validation, e1RM calculations

### Mobile (iOS + watchOS)

Open the Xcode project:

```bash
cd mobile/strykr
open strykr.xcodeproj
```

**Build and run:**
1. Select target: `strykr` (iOS) or `strykr Watch App` (watchOS)
2. Select simulator or connected device
3. ⌘R to build and run

**Configuration:**
- Update `Info.plist` with API Gateway endpoint
- Configure Cognito User Pool ID and App Client ID
- Set up Sign in with Apple entitlements in Apple Developer portal

**Note:** The watch app is currently a "hello world" placeholder. Full workout display and logging will be implemented in a future iteration.

---

## Deployment

### Initial Setup

1. **Clone repository:**
   ```bash
   git clone <repo-url>
   cd styrkr
   ```

2. **Configure Terraform backend:**
   Edit `terraform/backend.tf` to point to your S3 bucket for state storage:
   ```hcl
   terraform {
     backend "s3" {
       bucket = "your-terraform-state-bucket"
       key    = "styrkr/terraform.tfstate"
       region = "us-east-2"
     }
   }
   ```

3. **Set Terraform variables:**
   Copy `terraform/terraform.tfvars.example` (if exists) or create `terraform/terraform.tfvars`:
   ```hcl
   app_name = "styrkr"
   domain   = "yourdomain.com"
   project  = "styrkr_app"
   region   = "us-east-1"
   
   # Optional: OAuth providers
   apple_app_id      = "com.yourteam.styrkr-sid"
   apple_key_id      = "YOUR_KEY_ID"
   apple_private_key = "BASE64_ENCODED_PRIVATE_KEY"
   apple_team_id     = "YOUR_TEAM_ID"
   
   google_client_id     = "YOUR_GOOGLE_CLIENT_ID"
   google_client_secret = "YOUR_GOOGLE_CLIENT_SECRET"
   ```

4. **Ensure Route53 hosted zone exists:**
   Terraform expects a hosted zone for `var.domain` to create DNS records for CloudFront and API Gateway.

### Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan -out=plan.out
terraform apply plan.out
```

**Resources created:**
- Cognito User Pool + App Client
- DynamoDB table (single-table design)
- Lambda functions + layers
- API Gateway HTTP API with JWT authorizer
- S3 bucket for static site
- CloudFront distribution
- ACM certificates for custom domains
- Route53 DNS records

**Outputs:**
- `api_endpoint`: API Gateway URL (e.g., `https://api.yourdomain.com`)
- `website_url`: CloudFront URL (e.g., `https://yourdomain.com`)
- `cognito_user_pool_id`: For mobile app configuration
- `cognito_app_client_id`: For mobile app configuration

### Deploy Frontend

After infrastructure is deployed:

```bash
cd static_site
npm run build
aws s3 sync build/ s3://$(terraform -chdir=../terraform output -raw website_bucket_name) --delete
aws cloudfront create-invalidation --distribution-id $(terraform -chdir=../terraform output -raw cloudfront_distribution_id) --paths "/*"
```

**TODO:** Add deployment script `scripts/deploy-frontend.sh` to automate this.

---

## Configuration

### Environment Variables

**React App (`static_site/.env`):**
```bash
REACT_APP_API_ENDPOINT=https://api.yourdomain.com
REACT_APP_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
REACT_APP_COGNITO_APP_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
REACT_APP_COGNITO_REGION=us-east-1
```

**Lambda Functions:**
Environment variables are set via Terraform in `lambdas.tf`:
- `DYNAMODB_TABLE`: Table name for single-table design
- `COGNITO_USER_POOL_ID`: For user validation
- `REGION`: AWS region

### AWS Profile

Ensure your AWS CLI is configured with appropriate credentials:

```bash
aws configure --profile styrkr
export AWS_PROFILE=styrkr
```

Or set `AWS_PROFILE` in your shell profile.

### Cognito Setup

**User Pool Configuration:**
- **Sign-in options:** Email, username (optional)
- **MFA:** Optional (recommended for production)
- **Password policy:** Minimum 8 characters, uppercase, lowercase, number, symbol
- **OAuth providers:** Apple, Google (configured via Terraform variables)

**App Client:**
- **Auth flows:** `ALLOW_USER_SRP_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH`
- **OAuth scopes:** `openid`, `email`, `profile`
- **Callback URLs:** Configure for mobile deep links (e.g., `styrkr://auth/callback`)

**Mobile Integration:**
- Use AWS Amplify SDK or native Cognito SDK for iOS
- Handle OAuth redirect for Sign in with Apple
- Store JWT tokens securely in Keychain

---

## API Overview

Base URL: `https://api.yourdomain.com`

All endpoints require `Authorization: Bearer <JWT>` header (except auth endpoints).

### Authentication
- `POST /auth/signup` - Register new user
- `POST /auth/login` - Login with email/password
- `POST /auth/refresh` - Refresh JWT token
- `POST /auth/logout` - Invalidate refresh token

### Profile
- `GET /profile` - Get user profile (1RMs, preferences)
- `PUT /profile` - Update user profile
- `POST /profile/1rm` - Update training maxes

### Plans
- `GET /plans` - List user's training plans
- `POST /plans` - Create new plan from template
- `GET /plans/:id` - Get plan details
- `PUT /plans/:id` - Update plan (e.g., mark as archived)
- `DELETE /plans/:id` - Delete plan

### Workouts
- `GET /plans/:id/weeks/:week` - Get workout for week N (rendered on-demand)
- `POST /plans/:id/overrides` - Create override (swap accessory, move day)
- `DELETE /plans/:id/overrides/:overrideId` - Remove override

### Logs
- `GET /logs` - List workout logs (paginated)
- `POST /logs` - Submit completed workout
- `GET /logs/:id` - Get log details
- `PUT /logs/:id` - Edit log (within 24h)

### Exercise Library
- `GET /exercises` - List user's exercise library
- `POST /exercises` - Add custom exercise
- `PUT /exercises/:id` - Update exercise (tags, notes)
- `DELETE /exercises/:id` - Remove exercise

### Mobility
- `GET /mobility` - Get mobility scorecard
- `POST /mobility/test` - Submit mobility test result
- `GET /mobility/history` - Get historical test results

### Analytics
- `GET /analytics/e1rm` - Get e1RM trend data
- `GET /analytics/volume` - Get volume/intensity over time
- `GET /analytics/completion` - Get workout completion percentage

**Note:** Endpoints are placeholders. Actual implementation will be added as Lambda functions are developed.

---

## Folder Structure

```
styrkr/
├── mobile/                      # iOS + watchOS app
│   ├── strykr/                  # Main iOS app
│   │   ├── strykr/              # iOS app target
│   │   │   ├── Assets.xcassets/ # App icons, images
│   │   │   ├── ContentView.swift
│   │   │   ├── strykrApp.swift  # App entry point
│   │   │   └── Info.plist
│   │   ├── strykr Watch App/    # watchOS companion
│   │   │   ├── Assets.xcassets/
│   │   │   ├── ContentView.swift
│   │   │   └── strykrApp.swift
│   │   └── strykr.xcodeproj/    # Xcode project
│   └── strykrPackage/           # Shared Swift package (future)
│       └── Sources/
│           └── strykrFeature/
│               └── ContentView.swift
├── static_site/                 # React web app
│   ├── public/                  # Static assets
│   ├── src/
│   │   ├── App.js               # Main React component
│   │   ├── App.css
│   │   ├── index.js             # Entry point
│   │   └── index.css
│   ├── build/                   # Production build output
│   ├── package.json
│   └── README.md
├── terraform/                   # Infrastructure as Code
│   ├── backend.tf               # Terraform state backend
│   ├── versions.tf              # Provider versions
│   ├── variables.tf             # Input variables
│   ├── terraform.tfvars         # Variable values (gitignored)
│   ├── data.tf                  # Data sources (Route53, etc.)
│   ├── local.tf                 # Local values
│   ├── outputs.tf               # Output values
│   ├── cognito.tf               # Cognito User Pool
│   ├── dynamodb.tf              # DynamoDB table
│   ├── apigw.tf                 # API Gateway + routes
│   ├── lambdas.tf               # Lambda functions + layers
│   ├── lambda_temp.tf           # Temporary test Lambda (will be removed)
│   ├── s3_website.tf            # S3 bucket for static site
│   ├── cloudfront.tf            # CloudFront distribution
│   ├── secrets.tf               # Secrets Manager (OAuth keys)
│   ├── lambda_profiles/         # Lambda: Profile management
│   │   ├── index.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── lambda_shared/           # Shared Lambda layer
│   │   └── nodejs/
│   │       └── utils.ts         # DynamoDB helpers, e1RM calc
│   ├── lambda_temp/             # Temporary test Lambda
│   │   ├── index.ts
│   │   ├── package.json
│   │   └── dist/
│   └── builds/                  # Lambda deployment packages
├── logs/                        # MCP server logs (local dev)
└── README.md                    # This file
```

---

## Testing & Linting

### Frontend (React)

**Run tests:**
```bash
cd static_site
npm test
```

Uses Jest + React Testing Library. Test files: `src/**/*.test.js`

**Linting:**
```bash
npm run lint  # TODO: Add ESLint script to package.json
```

**TODO:** Add Prettier configuration and pre-commit hooks.

### Backend (Lambda)

**Unit tests:**
```bash
cd terraform/lambda_profiles
npm test  # TODO: Add Jest configuration
```

**TODO:** Add integration tests with DynamoDB Local and API Gateway Local.

### Mobile (iOS)

**Run tests:**
```bash
cd mobile/strykr
xcodebuild test -scheme strykr -destination 'platform=iOS Simulator,name=iPhone 15'
```

**TODO:** Add XCTest suite for workout generation logic, e1RM calculations, and date handling.

---

## Roadmap

- [ ] **Core Workout Engine:** Implement 5/3/1 Krypteia progression logic in Lambda
- [ ] **DynamoDB Schema:** Finalize single-table design with access patterns
- [ ] **User Onboarding:** 1RM input flow + plan creation
- [ ] **Workout Display:** Render week N with sets/reps/weights in iOS app
- [ ] **Logging:** Submit completed workout from iOS app
- [ ] **Analytics:** e1RM trend chart, volume/intensity graphs
- [ ] **Floating Week:** Implement day-swapping logic with constraints
- [ ] **Accessory Swaps:** Tag-based substitution engine
- [ ] **Mobility Scorecard:** Hip mobility tests + progress tracking
- [ ] **Exercise Library:** CRUD operations in settings
- [ ] **Watch App:** Display current workout, log sets on wrist
- [ ] **Offline Mode:** Cache workouts locally, sync logs when online
- [ ] **Push Notifications:** Workout reminders, deload week alerts
- [ ] **Export:** CSV/PDF export of training logs
- [ ] **Multi-Program Support:** Add other templates (5/3/1 BBB, Texas Method, etc.)

---

## Security

- **Authentication:** All API endpoints (except auth) require valid Cognito JWT
- **Authorization:** User ID extracted from JWT; users can only access their own data
- **Secrets:** OAuth client secrets stored in AWS Secrets Manager, injected into Terraform via variables
- **No Secrets in Repo:** `terraform.tfvars` is gitignored; use environment variables or AWS Secrets Manager for sensitive values
- **HTTPS Only:** CloudFront and API Gateway enforce TLS 1.2+
- **CORS:** Configured to allow only specified origins (web app + mobile deep links)
- **DynamoDB:** Point-in-time recovery enabled; encryption at rest by default
- **Lambda:** Least-privilege IAM roles; functions can only access required DynamoDB tables

**Production Checklist:**
- [ ] Enable MFA for Cognito users
- [ ] Rotate OAuth client secrets regularly
- [ ] Enable AWS CloudTrail for audit logging
- [ ] Set up AWS GuardDuty for threat detection
- [ ] Configure AWS WAF rules for API Gateway
- [ ] Review IAM policies for least privilege
- [ ] Enable S3 bucket versioning for static site
