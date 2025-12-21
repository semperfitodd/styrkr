data "aws_iam_policy_document" "lambda_library_publisher" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.config.arn,
      "${aws_dynamodb_table.config.arn}/index/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = [
      module.config_s3_bucket.s3_bucket_arn,
      "${module.config_s3_bucket.s3_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_library_publisher" {
  name        = "${var.project}_lambda_library_publisher"
  description = "DynamoDB and S3 access for library publisher Lambda"
  policy      = data.aws_iam_policy_document.lambda_library_publisher.json
}

module "lambda_library_publisher" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "${var.project}_library_publisher"
  description   = "Exercise library publisher for Styrkr"
  handler       = "handler.handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 60
  memory_size   = 512

  environment_variables = {
    CONFIG_TABLE_NAME  = aws_dynamodb_table.config.name
    CONFIG_BUCKET_NAME = module.config_s3_bucket.s3_bucket_id
    CONFIG_PREFIX      = "config/"
    DEBOUNCE_SECONDS   = "30"
  }

  source_path = [
    {
      path = "${path.module}/lambdas/library_publisher"
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
    aws_iam_policy.lambda_library_publisher.arn
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

# DynamoDB Stream Event Source Mapping
resource "aws_lambda_event_source_mapping" "library_stream" {
  event_source_arn  = aws_dynamodb_table.config.stream_arn
  function_name     = module.lambda_library_publisher.lambda_function_name
  starting_position = "LATEST"
  batch_size        = 100
  maximum_batching_window_in_seconds = 5

  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["INSERT", "MODIFY", "REMOVE"]
        dynamodb = {
          Keys = {
            PK = {
              S = [{ prefix = "LIBRARY#" }]
            }
          }
        }
      })
    }
  }

  depends_on = [
    module.lambda_library_publisher,
    aws_dynamodb_table.config
  ]
}

# Additional IAM permission for Lambda to read DynamoDB streams
resource "aws_iam_role_policy" "lambda_stream_policy" {
  name = "${var.project}_lambda_library_stream"
  role = module.lambda_library_publisher.lambda_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ]
        Resource = [
          aws_dynamodb_table.config.stream_arn
        ]
      }
    ]
  })
}

