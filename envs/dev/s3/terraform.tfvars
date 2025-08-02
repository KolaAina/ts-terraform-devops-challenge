project_id            = "kolam"
bucket_base_name      = "s3-deploy-artifacts"
aws_region            = "us-east-1"
versioning_enabled    = true
enable_kms_encryption = true
create_kms_key        = true
kms_key_arn           = null # or "arn:aws:kms:...:key/..." if you have one

github_owner  = "KolaAina"
github_repo   = "ts-terraform-devops-challenge"
github_branch = "main" # must match your workflow triggers

aws_account_id             = "443370701422"
existing_oidc_provider_arn = null # or # set if you already have it
#existing_oidc_provider_arn = "arn:aws:iam::443370701422:oidc-provider/token.actions.githubusercontent.com" # set if you already have it

tags = {
  Project = "kolam"
  Owner   = "kolam"
}
