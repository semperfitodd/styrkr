resource "aws_dynamodb_table" "main" {
  name         = "${var.project}_data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userEmail"
  range_key    = "dataType"

  attribute {
    name = "userEmail"
    type = "S"
  }

  attribute {
    name = "dataType"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project}_data"
  })
}

resource "aws_dynamodb_table" "workout_history" {
  name         = "${var.project}_workout_history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userEmail"
  range_key    = "workoutDate"

  attribute {
    name = "userEmail"
    type = "S"
  }

  attribute {
    name = "workoutDate"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project}_workout_history"
  })
}
