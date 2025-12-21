module "lambda_workout" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "${var.project}_workout"
  description   = "Workout history management for Styrkr"
  handler       = "handler.handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 30
  memory_size   = 256

  environment_variables = {
    WORKOUT_TABLE = aws_dynamodb_table.workout_history.name
    DATA_TABLE    = aws_dynamodb_table.main.name
  }

  source_path = [
    {
      path = "${path.module}/lambdas/workout"
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
  number_of_policies = 2
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    aws_iam_policy.lambda_workout_dynamodb.arn
  ]

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  cloudwatch_logs_retention_in_days = 7

  tags = var.tags
}

resource "aws_iam_policy" "lambda_workout_dynamodb" {
  name        = "${var.project}_lambda_workout_dynamodb"
  description = "IAM policy for workout Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.workout_history.arn,
          "${aws_dynamodb_table.workout_history.arn}/index/*"
        ]
      }
    ]
  })

  tags = var.tags
}

