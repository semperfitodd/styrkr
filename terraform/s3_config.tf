locals {
  config_bucket_name = "${var.app_name}-config-${random_string.this.result}"
}

data "aws_iam_policy_document" "config_bucket" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      values   = [module.cdn.cloudfront_distribution_arn]
      variable = "AWS:SourceArn"
    }
    actions   = ["s3:GetObject"]
    resources = ["${module.config_s3_bucket.s3_bucket_arn}/*"]
  }
}

module "config_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket = local.config_bucket_name

  attach_public_policy = false
  attach_policy        = true
  policy               = data.aws_iam_policy_document.config_bucket.json

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  expected_bucket_owner = data.aws_caller_identity.current.account_id

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = local.config_bucket_name
  })
}


