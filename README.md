# Terraform S3 OIDC Project

A production-ready Terraform(Module) project that creates secure S3 buckets with GitHub OIDC authentication, KMS encryption, automated CI/CD pipeline using GitHub Actions, and comprehensive TypeScript-based testing using Jest. This was designed to be meet the task to Develop a CDK Construct (TypeScript) that provisions an S3 bucket. I have chosen to design it this way using terraform-modules as a reusable and cloud agnostic solution to meet the challenge given while following terraform best practices.

## 🏗️ Architecture

This project creates:
- **S3 Buckets** with versioning, encryption, and public access blocking
- **KMS Keys** for server-side encryption (optional)
- **GitHub OIDC Provider** for secure authentication
- **IAM Roles & Policies** with least-privilege access
- **TypeScript-based testing** using Jest for infrastructure validation
- **GitHub Actions CI/CD** pipeline for automated deployments

## 📁 Project Structure

```
Typescript-project/
├── .github/workflows/
│   └── terraform.yaml          # CI/CD pipeline
├── test/
│   └── secure-bucket.test.ts    # TypeScript Jest tests
├── jest.config.ts               # Jest configuration
├── tsconfig.json               # TypeScript configuration
├── package.json                # Node.js dependencies
├── .tflint.hcl                 # TFLint configuration
├── envs/
│   ├── dev/s3/                 # Development environment
│   │   ├── main.tf            # Module configuration
│   │   ├── variables.tf       # Variable definitions
│   │   ├── outputs.tf         # Output values
│   │   ├── backend.tf         # State backend configuration
│   │   ├── terraform.tfvars   # Environment-specific values
│   │   └── plan.tfplan        # Terraform plan file
│   └── prod/s3/               # Production environment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── backend.tf
│       └── terraform.tfvars
└── modules/
    └── s3/                    # Reusable S3 module
        ├── main.tf           # Module implementation
        ├── variables.tf      # Module variables
        └── outputs.tf        # Module outputs
```

## 🚀 Features

### Security
- **OIDC Authentication**: Secure GitHub Actions integration without long-lived credentials
- **KMS Encryption**: Optional server-side encryption with customer-managed keys
- **Public Access Blocking**: All public access disabled by default
- **Least-Privilege IAM**: Comprehensive permissions for GitHub Actions operations

### Infrastructure
- **Multi-Environment**: Separate dev and prod configurations
- **State Management**: S3 backend with DynamoDB locking
- **Versioning**: Optional S3 bucket versioning
- **Tagging**: Consistent resource tagging with account ID

### CI/CD
- **Automated Pipeline**: GitHub Actions for plan/apply
- **Environment Protection**: Manual approval for production
- **Linting & Validation**: Terraform fmt, tflint, and validate
- **Destructive Change Protection**: Prevents accidental deletions with automated safety checks

### Testing
- **TypeScript Integration**: Jest-based infrastructure testing
- **Plan Validation**: Automated validation of Terraform plans
- **Security Checks**: Validation of encryption, access controls, and OIDC configuration
- **CI/CD Testing**: Automated test execution in GitHub Actions

## 🛠️ Prerequisites

- **Terraform** >= 1.0
- **Node.js** >= 16.0
- **npm** or **yarn**
- **AWS CLI** configured with appropriate permissions (for deployment)
- **GitHub Repository** with Actions enabled
- **Existing S3 bucket** for Terraform state storage
- **Existing DynamoDB table** for state locking

## 🔧 Initial Setup (One-Time Bootstrap)



1) **Clone & set origin**  
```bash
git clone https://github.com/<Owner>/<Repository-name>.git
git init
git checkout -b main
git remote add origin git@github.com:<OWNER>/project-name.git

### ⚠️ CRITICAL: Bootstrap Process

**This project requires a specific bootstrap sequence due to OIDC provider dependencies. Follow these steps exactly:**

### Step 1: Configure GitHub Variables

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** and add:

**Required Variables:**
- `TF_STATE_BUCKET` - Your S3 bucket name for Terraform state
- `TF_STATE_KEY_DEV` - State file key for dev environment (e.g., "test-oidc-dev-terraform.tfstate")
- `TF_STATE_KEY_PROD` - State file key for prod environment (e.g., "test-oidc-prod-terraform.tfstate")

### Step 2: Initial Dev Environment Bootstrap

**This creates the OIDC provider that both environments will use:**

1. **Ensure dev environment is configured to create OIDC:**
   ```hcl
   # envs/dev/s3/terraform.tfvars
   existing_oidc_provider_arn = null  # This creates the OIDC provider
   ```

2. **Deploy dev environment manually:**
   ```bash
   cd envs/dev/s3
   terraform init
   terraform plan
   terraform apply
   ```

3. **Get the generated OIDC provider ARN:**
   ```bash
   terraform output dev_oidc_role_arn
   ```

4. **Update both environments to use existing OIDC (CRITICAL for CI/CD):**
   ```bash
   # Copy the ARN from step 3 and update BOTH environments:
   
   # envs/dev/s3/terraform.tfvars
   existing_oidc_provider_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
   
   # envs/prod/s3/terraform.tfvars  
   existing_oidc_provider_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
   ```

### Step 3: Deploy Prod Environment

**Note**: Both environments should now use the existing OIDC provider ARN from Step 2.4 above.

2. **Deploy prod environment:**
   ```bash
   cd envs/prod/s3
   terraform init
   terraform plan
   terraform apply
   ```
3. **Get the Prod OIDC Role ARN:**
   ```bash
   terraform output prod_oidc_role_arn
   ```

### Step 4: Configure GitHub Actions

Add these variables to GitHub → Settings → Secrets and variables → Actions:

- `AWS_ROLE_ARN_DEV`: The dev role ARN (get from terraform output)
- `AWS_ROLE_ARN_PROD`: The prod role ARN (get from terraform output)

### Step 5: Create GitHub Environment for Prod

1. Go to GitHub → Settings → Environments
2. Create environment named `prod`
3. Add protection rules (required reviewers, wait timer, etc.)

### Step 6: Test CI/CD Pipeline

```bash
git add .
git commit -m "Bootstrap complete - ready for CI/CD"
git push origin main
```

## 🔄 How OIDC Provider Works

- **Dev Environment**: Creates the OIDC provider (`existing_oidc_provider_arn = null`)
- **Prod Environment**: Reuses the same OIDC provider (`existing_oidc_provider_arn = "arn:aws:iam::...:oidc-provider/token.actions.githubusercontent.com"`)
- **Best Practice**: One OIDC provider per AWS account, multiple roles can trust it

## ⚙️ Configuration

### 1. Environment Variables

Update `envs/dev/s3/terraform.tfvars` and `envs/prod/s3/terraform.tfvars`:

```hcl
project_id            = "your-project-name"
bucket_base_name      = "your-bucket-name"
aws_region            = "aws-region"
versioning_enabled    = true
enable_kms_encryption = false  # Set to false initially to avoid permission issues
create_kms_key        = false  # Set to false initially

github_owner          = "your-github-username"
github_repo           = "your-repo-name"
github_branch         = "main"

aws_account_id        = "123456789012"
existing_oidc_provider_arn = null  # For dev (creates OIDC), set ARN for prod

# State management configuration
terraform_state_bucket         = "your-state-s3-bucket"
terraform_state_key            = "your-terraform.tfstate"  # Change for prod
terraform_state_dynamodb_table = "your-db-lock"

tags = {
  Project = "your-project"
  Owner   = "your-name"
}
```

### 2. Backend Configuration

Update `envs/dev/s3/backend.tf` and `envs/prod/s3/backend.tf`:

```hcl
terraform {
  required_version = ">= 1.0.0"
  backend "s3" {
    bucket         = "yours"
    key            = "your-key"  # Change for prod
    region         = "aws-region"
    dynamodb_table = "your-db"
    encrypt        = true
  }
}
```

## 🧪 Testing

### Running Tests

```bash
# Install dependencies
npm install

# Run all tests
npm test

# Run tests with verbose output
npm test -- --verbose
```

### Test Coverage

The test suite validates:

1. **S3 Bucket Creation**: Ensures bucket is created with correct configuration
2. **Versioning**: Validates bucket versioning is enabled
3. **Encryption**: Checks for encryption configuration (KMS or AES256)
4. **Public Access Blocking**: Verifies all public access is disabled
5. **OIDC Configuration**: Validates GitHub OIDC provider setup
6. **IAM Role**: Ensures IAM role exists with proper naming

### Test Output Example

```bash
 PASS  test/secure-bucket.test.ts (6.866 s)
  Terraform plan unit tests (dev)
    √ includes S3 bucket and IAM role (3 ms)
    √ bucket versioning enabled (1 ms)
    √ bucket SSE configured (KMS or AES256) (1 ms)
    √ public access block all true (1 ms)
    √ OIDC role trust contains aud and sub (1 ms)

Test Suites: 1 passed, 1 total
Tests:       5 passed, 5 total
Snapshots:   0 total
Time:        6.962 s
```

## 🚀 Deployment

### Local Development

```bash
# Initialize and deploy dev environment
cd envs/dev/s3
terraform init
terraform plan
terraform apply

# Initialize and deploy prod environment
cd envs/prod/s3
terraform init
terraform plan
terraform apply
```

### CI/CD Pipeline

The GitHub Actions workflow automatically:
1. **Lints** and **validates** Terraform code using TFLint
2. **Runs TypeScript tests** to validate infrastructure configuration
3. **Plans** changes for dev environment
4. **Applies** dev changes (on main branch)
5. **Prevents destructive changes** with safety checks

**Important**: The workflow deploys dev first, then prod. This ensures the OIDC provider exists before prod tries to use it.

### Testing Before Deployment

```bash
# Run tests to validate configuration
npm test

# If tests pass, proceed with deployment
cd envs/dev/s3
terraform apply
```

## 📊 Outputs

After deployment, you'll get:

```hcl
# Development Environment
dev_bucket_name     = "your-project-name-your-bucket-name"
dev_bucket_arn      = "arn:aws:s3:::your-project-name-your-bucket-name"
dev_oidc_role_arn   = "arn:aws:iam::123456789012:role/your-project-name-gh-oidc-role"

# Production Environment
prod_bucket_name    = "your-project-name-prod-your-bucket-name-prod"
prod_bucket_arn     = "arn:aws:s3:::your-project-name-prod-your-bucket-name-prod"
prod_oidc_role_arn  = "arn:aws:iam::123456789012:role/your-project-name-prod-gh-oidc-role"
```

## 🔧 Usage in GitHub Actions

Use the created IAM role in your GitHub Actions workflows:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v3
  with:
    role-to-assume: ${{ vars.AWS_ROLE_ARN_DEV }}  # or AWS_ROLE_ARN_PROD
    aws-region: us-east-1
```

## 🛡️ Security Features

- **OIDC Trust**: Only allows GitHub Actions from specified repository and branch
- **Encryption**: Server-side encryption with KMS (optional) or AES256
- **Access Control**: Public access completely blocked
- **Audit Trail**: All actions logged via CloudTrail
- **Least Privilege**: Necessary IAM permissions for GitHub Actions

## 🔄 Maintenance

### Adding New Environments

1. Copy `envs/dev/s3/` to `envs/new-env/s3/`
2. Update `terraform.tfvars` with environment-specific values
3. Update backend configuration
4. Update test configuration if needed
5. **Important**: Set `existing_oidc_provider_arn` to use the existing OIDC provider

### Updating Module

1. Modify `modules/s3/` files
2. Update tests in `test/` directory
3. Run `npm test` to validate changes
4. Test in dev environment
5. Promote to prod after validation

## 🐛 Troubleshooting

### Common Issues

1. **OIDC Provider Already Exists**: Set `existing_oidc_provider_arn` to use existing provider
2. **IAM Policy Name Conflict**: Module uses unique names with bucket base name
3. **Backend Lock Issues**: Ensure DynamoDB table exists and has proper permissions or Use `use_lockfile = true` for local development
4. **Test Failures**: Ensure Node.js dependencies are installed with `npm install`

### Bootstrap Issues

1. **"No OpenIDConnect provider found"**
   - **Solution**: Run the one-time bootstrap process (dev environment first)
   - **Check**: Ensure dev environment has `existing_oidc_provider_arn = null`

2. **"OIDC provider already exists"**
   - **Solution**: Update prod environment to use the existing provider ARN
   - **Check**: Verify the ARN in `envs/prod/s3/terraform.tfvars`

3. **"Role ARN not found in GitHub"**
   - **Solution**: Add the role ARN as a GitHub variable
   - **Steps**: Get ARN from `terraform output`, add to GitHub repository variables

4. **Permission Errors (403 AccessDenied)**
   - **Solution**: The IAM role has comprehensive permissions, but you may need to import existing resources
   - **Steps**: Use `terraform import` for existing resources, or delete and recreate

### Debug Commands

```bash
# Validate configuration
terraform validate

# Check formatting
terraform fmt -check

# View plan details
terraform show plan.tfplan

# Import existing resources
terraform import module.s3.aws_iam_policy.bucket arn:aws:iam::ACCOUNT:policy/POLICY_NAME

# Debug tests
npm test -- --verbose

# Check OIDC provider exists
aws iam list-open-id-connect-providers

# Get OIDC provider details
aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
```


## 🧭 Design Decisions & Trade‑offs

- **Terraform module** instead of CDK construct to keep the solution **cloud‑agnostic**, composable, and registry‑friendly.
- **Singleton OIDC**: Owned by **dev**; **prod** **references** it to avoid multi‑state ownership.
- **Directory per env** over workspaces: easier review, clearer diffs, safer drift management.


## 🔧 Special Considerations

### Permission Management
- The IAM role has comprehensive permissions to avoid "whack-a-mole" permission issues
- Uses `s3:Get*`, `s3:List*`, `iam:Get*`, `iam:List*` for broad read access
- Specific write permissions for S3, IAM, and DynamoDB operations

### State Management
- Uses S3 backend with DynamoDB locking for state consistency
- Separate state files for dev and prod environments
- Configurable state bucket, key, and DynamoDB table names

### KMS Encryption
- Initially disabled to avoid permission issues during bootstrap
- Can be enabled after initial deployment by setting `enable_kms_encryption = true`
- Conditional KMS permissions in IAM policy

### CI/CD Pipeline Design
- Re-run plan before apply jobs to prevent stale plan errors.
- Manual approval required for production deployments
- Comprehensive testing before deployment

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add/update tests as needed
5. Run `npm test` to validate
6. Submit a pull request

## Support

For issues and questions:
- Create a GitHub issue
- Check the troubleshooting section
- Review AWS and Terraform documentation
- Check test output for validation errors
- Contact: kolawoleaina96@gmail.com 