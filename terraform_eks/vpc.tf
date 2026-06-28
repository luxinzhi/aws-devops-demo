data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "tf-state-demo-269523617138-20260628"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}