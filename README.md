# Terraform S3 OIDC Project

A production-ready Terraform project that creates secure S3 buckets with GitHub OIDC authentication, KMS encryption, automated CI/CD pipeline using GitHub Actions, and comprehensive TypeScript-based testing using Jest.

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
- **Least-Privilege IAM**: Minimal required permissions for GitHub Actions

### Infrastructure
- **Multi-Environment**: Separate dev and prod configurations
- **State Management**: S3 backend with locking
- **Versioning**: Optional S3 bucket versioning
- **Tagging**: Consistent resource tagging

### CI/CD
- **Automated Pipeline**: GitHub Actions for plan/apply
- **Environment Protection**: Manual approval for production
- **Linting & Validation**: Terraform fmt, tflint, and validate
- **Destructive Change Protection**: Prevents accidental deletions

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

## 🔧 Initial Setup (One-Time Bootstrap)

### Step 1: Configure GitHub Variables

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** and add:

**Required Variables:**
- `TF_STATE_BUCKET` - Your S3 bucket name for Terraform state
- `TF_STATE_KEY_DEV` - State file key for dev environment (e.g., "s3-oidc-dev-terraform.tfstate")
- `TF_STATE_KEY_PROD` - State file key for prod environment (e.g., "s3-oidc-prod-terraform.tfstate")

### Step 2: One-Time Bootstrap (Manual)

**Important**: This is a one-time setup that creates the OIDC provider in your AWS account.

1. **Deploy Dev Environment First:**
   ```bash
   cd envs/dev/s3
   terraform init
   terraform plan
   terraform apply
   ```

2. **Get the OIDC Role ARN:**
   ```bash
   terraform output dev_oidc_role_arn
   ```

3. **Add OIDC Role ARN to GitHub:**
   - Go to GitHub → Settings → Secrets and variables → Actions
   - Add variable: `AWS_ROLE_ARN_DEV` with the ARN from step 2

4. **Deploy Prod Environment:**
   ```bash
   cd ../../prod/s3
   terraform init
   terraform plan
   terraform apply
   ```

5. **Get the Prod OIDC Role ARN:**
   ```bash
   terraform output prod_oidc_role_arn
   ```

6. **Add Prod OIDC Role ARN to GitHub:**
   - Add variable: `AWS_ROLE_ARN_PROD` with the ARN from step 5

### Step 3: Verify Bootstrap

After bootstrap, you should have:
- ✅ **One OIDC Provider** in your AWS account (created by dev)
- ✅ **Two IAM Roles** (dev and prod) that trust the same OIDC provider
- ✅ **GitHub Variables** configured for CI/CD
- ✅ **S3 Buckets** created for both environments

### Step 4: Test CI/CD Pipeline

```bash
git add .
git commit -m "Initial setup complete"
git push origin main
```

The CI/CD pipeline should now work with OIDC authentication!

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
aws_region            = "us-east-1"
versioning_enabled    = true
enable_kms_encryption = true
create_kms_key        = true
kms_key_arn           = null  # or existing KMS key ARN

github_owner          = "your-github-username"
github_repo           = "your-repo-name"
github_branch         = "main"

aws_account_id        = "123456789012"
existing_oidc_provider_arn = null  # or existing OIDC provider ARN

tags = {
  Project = "your-project"
  Owner   = "your-name"
}
```

### 3. GitHub Actions Setup

1. **Repository Variables**: Set in GitHub → Settings → Secrets and variables → Actions:
   - `AWS_ROLE_ARN_DEV`: ARN of the dev IAM role (output after first deployment)

2. **Environment Protection**: Configure GitHub Environments for `dev` with appropriate protection rules.

### 2. Backend Configuration

Update `envs/dev/s3/backend.tf` and `envs/prod/s3/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket       = "your-terraform-state-bucket"
    key          = "s3-oidc-dev-terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
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
3. **Encryption**: Checks for KMS encryption configuration
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
- **Encryption**: Server-side encryption with KMS (optional)
- **Access Control**: Public access completely blocked
- **Audit Trail**: All actions logged via CloudTrail
- **Least Privilege**: Minimal IAM permissions for GitHub Actions

## 🔄 Maintenance

### Adding New Environments

1. Copy `envs/dev/s3/` to `envs/new-env/s3/`
2. Update `terraform.tfvars` with environment-specific values
3. Update backend configuration
4. Update test configuration if needed

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
3. **Backend Lock Issues**: Use `use_lockfile = true` for local development
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

## �� Setup Instructions

### 1. Initial Setup
```bash
# Clone your repository
git clone https://github.com/<Owner>/<Repository-name>.git
cd <Repository-name>

# Install Node.js dependencies
npm install

# Update configuration files
# - envs/dev/s3/terraform.tfvars
# - envs/prod/s3/terraform.tfvars
# - envs/dev/s3/backend.tf
# - envs/prod/s3/backend.tf

# Test configuration
npm test

# Commit and push changes
git add .
git commit -m "Update configuration for deployment"
git push origin main
```

### 2. First Deployment

1. **Create S3 Backend Bucket**: Create the S3 bucket specified in your backend configuration
2. **Deploy Dev Environment**: 
   ```bash
   cd envs/dev/s3
   terraform init
   terraform apply
   ```
3. **Capture IAM Role ARN**: Note the IAM role ARN from the deployment outputs

### 3. Configure GitHub Actions

After deployment, update your GitHub repository variables:
- `AWS_ROLE_ARN_DEV`: Use the dev role ARN from deployment outputs

### 4. Trigger CI/CD Pipeline

1. **Push to main branch**: This will trigger the GitHub Actions workflow
2. **Monitor deployment**: Check Actions tab for deployment progress
3. **Verify infrastructure**: The pipeline will automatically test and deploy changes


## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add/update tests as needed
5. Run `npm test` to validate
6. Submit a pull request


For issues and questions, mail me: kolawoleaina96@gmail.com
- Create a GitHub issue
- Check the troubleshooting section
- Review AWS and Terraform documentation
- Check test output for validation errors 