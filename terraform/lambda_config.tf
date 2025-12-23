module "lambda_config" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.project}_config"
  description   = "Handle public config endpoints (no auth)"
  handler       = "handler.handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 30

  source_path = [
    {
      path = "${path.module}/lambdas/config"
    },
    {
      path             = "${path.module}/lambdas/shared"
      prefix_in_zip    = "shared"
      patterns         = ["!__pycache__/.*", "!\\.pytest_cache/.*"]
    }
  ]

  environment_variables = {
    CONFIG_BUCKET = module.config_s3_bucket.s3_bucket_id
  }

  attach_policy_statements = true
  policy_statements = {
    s3_read = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        module.config_s3_bucket.s3_bucket_arn,
        "${module.config_s3_bucket.s3_bucket_arn}/*"
      ]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = var.tags
}

module "lambda_nonlift" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.project}_nonlift"
  description   = "Generate non-lifting day workouts (with auth)"
  handler       = "handler.handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 30

  source_path = [
    {
      path = "${path.module}/lambdas/nonlift"
    },
    {
      path             = "${path.module}/lambdas/shared"
      prefix_in_zip    = "shared"
      patterns         = ["!__pycache__/.*", "!\\.pytest_cache/.*"]
    }
  ]

  environment_variables = {
    DATA_TABLE    = aws_dynamodb_table.main.name
    CONFIG_BUCKET = module.config_s3_bucket.s3_bucket_id
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem"
      ]
      resources = [aws_dynamodb_table.main.arn]
    }
    s3_read = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        module.config_s3_bucket.s3_bucket_arn,
        "${module.config_s3_bucket.s3_bucket_arn}/*"
      ]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = var.tags
}


module "lambda_program_settings" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.project}_program_settings"
  description   = "Handle program settings (with auth)"
  handler       = "handler.handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 30

  source_path = [
    {
      path = "${path.module}/lambdas/program_settings"
    },
    {
      path             = "${path.module}/lambdas/shared"
      prefix_in_zip    = "shared"
      patterns         = ["!__pycache__/.*", "!\\.pytest_cache/.*"]
    }
  ]

  environment_variables = {
    DATA_TABLE = aws_dynamodb_table.main.name
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      resources = [aws_dynamodb_table.main.arn]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = var.tags
}

module "lambda_program_week" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.project}_program_week"
  description   = "Render program week sessions (with auth)"
  handler       = "handler.handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 30

  source_path = [
    {
      path = "${path.module}/lambdas/program_week"
    },
    {
      path             = "${path.module}/lambdas/shared"
      prefix_in_zip    = "shared"
      patterns         = ["!__pycache__/.*", "!\\.pytest_cache/.*"]
    }
  ]

  environment_variables = {
    DATA_TABLE    = aws_dynamodb_table.main.name
    CONFIG_BUCKET = module.config_s3_bucket.s3_bucket_id
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:Query"
      ]
      resources = [aws_dynamodb_table.main.arn]
    }
    s3_read = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        module.config_s3_bucket.s3_bucket_arn,
        "${module.config_s3_bucket.s3_bucket_arn}/*"
      ]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = var.tags
}
