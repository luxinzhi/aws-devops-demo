provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "aws-devops-demo"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}