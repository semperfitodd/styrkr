resource "aws_dynamodb_table" "temp" {
  name         = "${var.project}_temp"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project}_temp"
  })
}
