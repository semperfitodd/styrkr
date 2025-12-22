module "lambda_schedule" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "${var.project}_schedule"
  description   = "Schedule customization management for Styrkr"
  handler       = "handler.handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 30
  memory_size   = 256

  environment_variables = {
    DATA_TABLE = aws_dynamodb_table.main.name
  }

  source_path = [
    {
      path = "${path.module}/lambdas/schedule"
      patterns = [
        "!.*/.*",
        "handler\\.py$"
      ]
    },
    {
      path          = "${path.module}/lambdas/shared"
      prefix_in_zip = "shared"
      patterns = [
        "!.*/.*",
        ".*\\.py$"
      ]
    }
  ]

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ]
      resources = [
        aws_dynamodb_table.main.arn
      ]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  cloudwatch_logs_retention_in_days = 7

  tags = var.tags
}

