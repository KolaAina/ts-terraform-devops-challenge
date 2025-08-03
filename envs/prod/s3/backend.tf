terraform {
  required_version = ">= 1.0.0"

  # Temporarily disabled for local testing
  # backend "s3" {
  #   # These will be overridden by -backend-config in CI/CD
  #   bucket         = "placeholder-bucket"
  #   key            = "placeholder-key"
  #   region         = "us-east-1"
  #   dynamodb_table = "kada-terraform-eks-state-lock"
  #   encrypt        = true
  # }
}
