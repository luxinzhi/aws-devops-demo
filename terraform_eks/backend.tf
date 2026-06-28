terraform {
  backend "s3" {
    bucket = "tf-state-demo-269523617138-20260628"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}