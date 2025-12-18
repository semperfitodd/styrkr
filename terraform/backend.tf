terraform {
  backend "s3" {
    bucket = "bernson.terraform"
    key    = "strykr/terraform.tfstate"
    region = "us-east-2"

    encrypt      = true
    use_lockfile = false
  }
}
