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
      aws_dynamodb_table.main.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "${var.project}_lambda_dynamodb"
  description = "DynamoDB access for Lambda functions"
  policy      = data.aws_iam_policy_document.lambda_dynamodb.json
}

