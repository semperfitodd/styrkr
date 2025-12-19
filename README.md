# STYRKR

## What Styrkr Does

Styrkr helps you get stronger over time—without breaking your body or your life.

You enter your current strength numbers, choose how many days you train, and Styrkr builds a structured strength plan that adapts to travel, missed days, and changing needs—while keeping long-term progress intact.

Unlike workout trackers that just record what you did, Styrkr tells you what to do next, based on proven strength programming and your actual training history.

## What You Get as a User
### A real strength plan, not random workouts

Styrkr generates a complete, long-term strength program based on your lifts. You can view any future week at any time and always know what’s coming next.

### Freedom without breaking the program

Travel or miss a day? You can move workouts within the week without ruining progression or recovery. The plan adapts to real life instead of forcing you into a rigid calendar.

### Smart exercise substitutions

If you can’t (or shouldn’t) do a certain accessory movement, Styrkr lets you swap it for another that serves the same purpose—without turning your program into chaos.

### Strength progress you can actually trust

Styrkr tracks estimated 1RM trends, training maxes, volume, and consistency so you can see whether you’re getting stronger over time—not just chasing one-off PRs.

### Mobility that’s measured, not guessed

Mobility work is built into your schedule and tracked with simple, repeatable tests—especially for hips—so you can see real improvement instead of relying on how things “feel.”

### Built for long-term use

Styrkr is designed for people who want to train hard for years. It prioritizes consistency, recovery, and durability so strength keeps going up as you age.

## Who Styrkr Is For

Styrkr is for lifters who:

* Care about increasing their total strength
* Train 3–6 days per week
* Travel or have unpredictable schedules
* Want structure without rigidity 
* Value longevity as much as performance

## Tech Stack

- **Frontend**: React 19, pure Cognito OAuth (no Amplify)
- **Mobile**: SwiftUI (iOS 18+)
- **Backend**: AWS Lambda (Node.js 20, TypeScript)
- **API**: API Gateway HTTP API
- **Auth**: AWS Cognito with Google OAuth & Apple Sign In
- **Database**: DynamoDB
- **CDN**: CloudFront + S3
- **IaC**: Terraform

## Prerequisites

- Node.js 18+
- Terraform 1.0+
- AWS CLI 2.x
- Xcode 15+ (for iOS)
- AWS Account with Route53 hosted zone

## Configuration

### React Web App

Create `static_site/.env`:
```bash
REACT_APP_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
REACT_APP_COGNITO_CLIENT_ID=XXXXXXXXXXXXXXXXXX
REACT_APP_COGNITO_DOMAIN=your-auth-domain.com
REACT_APP_REDIRECT_URI=https://your-domain.com/auth/callback
REACT_APP_LOGOUT_URI=https://your-domain.com/logout
```

### iOS App

Copy `mobile/strykr/strykr/Secrets.swift.example` to `Secrets.swift` and update:
```swift
struct Secrets {
    static let apiBaseURL = "https://your-api-domain.com"
    static let cognitoClientId = "YOUR_CLIENT_ID"
    static let cognitoDomain = "your-auth-domain.com"
    static let cognitoUserPoolId = "us-east-1_XXXXXXXXX"
    static let logoutUri = "styrkr://logout"
    static let redirectUri = "styrkr://auth/callback"
}
```

### Terraform

Create `terraform/terraform.tfvars`:
   ```hcl
   app_name = "styrkr"
   domain   = "yourdomain.com"
   project  = "styrkr_app"
   region   = "us-east-1"
   
apple_app_id      = "com.yourteam.styrkr-pid"
   apple_key_id      = "YOUR_KEY_ID"
   apple_private_key = "BASE64_ENCODED_PRIVATE_KEY"
   apple_team_id     = "YOUR_TEAM_ID"
   
   google_client_id     = "YOUR_GOOGLE_CLIENT_ID"
   google_client_secret = "YOUR_GOOGLE_CLIENT_SECRET"
   ```

## OAuth Provider Setup

### Google OAuth

Console: https://console.cloud.google.com/apis/credentials

**Authorized JavaScript origins:**
```
https://your-domain.com
https://your-auth-domain.com
```

**Authorized redirect URIs:**
```
https://your-domain.com/auth/callback
https://your-auth-domain.com/oauth2/idpresponse
```

### Apple Sign In

Console: https://developer.apple.com/account/resources/identifiers/list/serviceId

**Domain:**
```
your-auth-domain.com
```

**Return URL:**
```
https://your-auth-domain.com/oauth2/idpresponse
```

## Deployment

### Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan -out=plan.out
terraform apply plan.out
```

### Deploy Frontend

```bash
cd static_site
npm install
npm run build
cd ../terraform
terraform apply  # Uploads build to S3
```

### Build iOS App

```bash
cd mobile/strykr
open strykr.xcodeproj
# Build and run in Xcode (⌘R)
```

## Local Development

### React

```bash
cd static_site
npm install
npm start  # http://localhost:3000
```

### iOS

Open `mobile/strykr/strykr.xcodeproj` in Xcode and run.

## Security

- No hardcoded secrets in code
- All secrets in `.env`, `terraform.tfvars`, or `Secrets.swift` (gitignored)
- HTTPS only
- Cognito JWT authentication
- OAuth 2.0 Authorization Code flow

## Project Structure

```
styrkr/
├── mobile/strykr/           # iOS app
│   ├── strykr/              # iOS target
│   └── strykr.xcodeproj/
├── static_site/             # React web app
│   ├── src/
│   ├── public/
│   └── build/
└── terraform/               # Infrastructure
    ├── *.tf
    └── lambda_temp/         # Lambda functions
```
