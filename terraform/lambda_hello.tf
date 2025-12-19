module "lambda_hello" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "${var.project}_hello"
  description   = "Health check endpoint for Styrkr"
  handler       = "handler.handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 10
  memory_size   = 128

  source_path = [
    {
      path = "${path.module}/lambdas/hello"
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

  attach_policies    = true
  number_of_policies = 1
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  cloudwatch_logs_retention_in_days = 3

  tags = var.tags
}

