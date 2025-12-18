data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      aws_dynamodb_table.temp.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "${var.project}_lambda_dynamodb"
  description = "DynamoDB access for Lambda functions"
  policy      = data.aws_iam_policy_document.lambda_dynamodb.json
}

module "lambda_temp" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "${var.project}_temp"
  description   = "Temporary hello world lambda"
  handler       = "index.handler"
  publish       = true
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 256

  environment_variables = {
    TEMP_TABLE = aws_dynamodb_table.temp.name
  }

  source_path = [
    {
      path             = "${path.module}/lambda_temp"
      npm_requirements = true
      commands = [
        "npm install",
        "npm run build",
        ":zip"
      ]
    }
  ]

  attach_policies    = true
  number_of_policies = 2
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    aws_iam_policy.lambda_dynamodb.arn
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
