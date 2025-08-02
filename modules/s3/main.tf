terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  bucket_name = "${var.project_id}-${var.bucket_base_name}"

  # Build trust subjects. You can extend this list (e.g., tags or PRs) if needed.
  github_sub = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
  
  # Common tags including account ID
  common_tags = merge(var.tags, {
    AccountId = var.aws_account_id
  })
}

# --- (Optional) KMS Key ---
resource "aws_kms_key" "bucket" {
  count                   = var.enable_kms_encryption && var.create_kms_key && var.kms_key_arn == null ? 1 : 0
  description             = "KMS key for ${local.bucket_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "bucket" {
  count         = length(aws_kms_key.bucket) == 1 ? 1 : 0
  name          = "alias/${local.bucket_name}"
  target_key_id = aws_kms_key.bucket[0].key_id
}

# Choose KMS key
locals {
  effective_kms_key_arn = var.enable_kms_encryption ? (var.kms_key_arn != null ? var.kms_key_arn : (length(aws_kms_key.bucket) == 1 ? aws_kms_key.bucket[0].arn : null)) : null
}

# --- S3 Bucket ---
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_kms_encryption ? 1 : 0
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.effective_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = local.effective_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# --- GitHub OIDC Provider (create if not provided) ---
resource "aws_iam_openid_connect_provider" "github" {
  count = var.existing_oidc_provider_arn == null ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  oidc_provider_arn = var.existing_oidc_provider_arn != null ? var.existing_oidc_provider_arn : aws_iam_openid_connect_provider.github[0].arn
}

# --- IAM Role trusted by GitHub OIDC ---
data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_sub]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_id}-gh-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = local.common_tags
}

# --- Least-privilege policy for bucket + optional KMS ---
data "aws_iam_policy_document" "bucket" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.this.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload"
    ]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }

  dynamic "statement" {
    for_each = local.effective_kms_key_arn != null ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
      ]
      resources = [local.effective_kms_key_arn]
    }
  }
}

resource "aws_iam_policy" "bucket" {
  name        = "${var.project_id}-bucket-access"
  description = "Access to ${local.bucket_name} and (optional) its KMS key"
  policy      = data.aws_iam_policy_document.bucket.json
  tags        = local.common_tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.bucket.arn
}
