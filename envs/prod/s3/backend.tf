terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    # These will be overridden by -backend-config in CI/CD
    bucket         = "kada-terraform-eks-state-s3-bucket"
    key            = "s3-new-oidc-prod-terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kada-terraform-eks-state-lock"
    encrypt        = true
  }
}
