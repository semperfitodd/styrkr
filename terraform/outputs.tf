output "api_url" {
  description = "API Gateway custom domain URL"
  value       = local.api_domain_name
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_domain" {
  description = "Cognito custom domain"
  value       = local.auth_domain
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "config_bucket_name" {
  description = "S3 bucket name for config snapshots"
  value       = module.config_s3_bucket.s3_bucket_id
}

output "frontend_url" {
  description = "Frontend website URL"
  value       = local.domain_name
}

output "library_latest_url" {
  description = "CloudFront URL for latest exercise library"
  value       = "https://${local.domain_name}/config/exercises.latest.json"
}

output "oauth_secrets_arn" {
  description = "ARN of the OAuth credentials secret in Secrets Manager"
  value       = aws_secretsmanager_secret.oauth_credentials.arn
}
