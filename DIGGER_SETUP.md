# Digger Integration Setup Guide

This guide walks you through setting up Digger for your scispace-infra EKS infrastructure project.

## Overview

Digger will replace HCP Terraform for orchestrating your Terraform infrastructure, providing:
- ✅ **Cost savings** - No additional compute costs
- ✅ **Security** - Secrets stay in your CI environment  
- ✅ **Concurrent execution** - Parallel runs for faster deployments
- ✅ **PR-level automation** - Plan/apply via PR comments
- ✅ **Drift detection** - Automated infrastructure monitoring

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub repository** with admin access
3. **Terraform** knowledge and existing project (✅ you have this)

## Step-by-Step Setup

### 1. Create Backend and OIDC Infrastructure

First, create the S3 bucket, DynamoDB table for Terraform state, and the AWS OIDC provider and IAM role for Digger. These are defined in `infra_prerequisites.tf` (which creates resources like `ss-terraform-state-us-west-2` bucket and `ss-terraform-locks` table).

**Important**: Before applying `oidc-digger-setup.tf`, ensure you have updated the `github_repository_path` local variable within the file to your actual GitHub organization and repository (e.g., `"your-org/your-repo"`).

```bash
# From the root directory of your project

# Initialize and apply backend-setup.tf (S3 bucket, DynamoDB table)
terraform -chdir=. init -upgrade # Assuming backend-setup.tf is in the root or a subdirectory
terraform -chdir=. plan -out=backend.plan # Review the plan
terraform -chdir=. apply backend.plan

# Initialize and apply oidc-digger-setup.tf (OIDC Provider, IAM Role for Digger)
# Ensure you are in the directory containing oidc-digger-setup.tf or adjust -chdir path
terraform -chdir=. init -upgrade # Assuming oidc-digger-setup.tf is in the root or a subdirectory
terraform -chdir=. plan -out=oidc.plan # Review the plan
terraform -chdir=. apply oidc.plan

# Note the output 'digger_github_actions_role_arn' from the apply of oidc-digger-setup.tf
# This ARN will be used for the AWS_ROLE_ARN GitHub secret.
```

If the `aws_iam_openid_connect_provider` resource in `oidc-digger-setup.tf` fails because the provider already exists in your AWS account, this is generally okay. The role creation will still use the known ARN for the provider.

### 2. Migrate Existing State to S3 Backend

After backend infrastructure is created, migrate your existing state. 
**Note**: First, rename your `tiptap-terraform` directory to `scispace-infra`.

```bash
# cd scispace-infra  # <--- CHANGED: Ensure you are in the renamed directory

# Initialize with new backend configuration (bucket: ss-terraform-state-us-west-2, table: ss-terraform-locks)
# terraform init -migrate-state # This command will be run after renaming the folder and cd-ing into it.

# For each workspace, migrate individually. Example for 'default' and a renamed 'stage' workspace:
# terraform workspace select default
# terraform init -migrate-state

# terraform workspace select stage # (Assuming you rename tiptap-stage to stage)
# terraform init -migrate-state
```

Ensure your `scispace-infra/versions.tf` file has the updated backend block:
```hcl
terraform {
  // ...
  backend "s3" {
    bucket         = "ss-terraform-state-us-west-2"
    key            = "terraform.tfstate" # Or e.g., "${terraform.workspace}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "ss-terraform-locks"
  }
  // ...
}
```

### 3. Configure GitHub Secrets

Add the following secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

#### Required Secrets

```bash
# AWS Authentication using OIDC (Recommended)
# Get this ARN from the output of applying 'oidc-digger-setup.tf'
AWS_ROLE_ARN=arn:aws:iam::YOUR_ACCOUNT:role/DiggerGithubActionsRole # Replace with actual output ARN

# Digger Configuration
DIGGER_ORG_ID=your_digger_org_id          # Get from digger.dev dashboard
DIGGER_TOKEN=your_digger_api_token        # Get from digger.dev dashboard

# Application Secrets
TIPTAP_DATABASE_URL=postgres://scispace_root:5b2uhtv5aK8z@scispace.c0fwkhspicdq.us-west-2.rds.amazonaws.com:5432/tiptap
TIPTAP_DATABASE_URL_DIRECT=postgres://scispace_root:5b2uhtv5aK8z@scispace.c0fwkhspicdq.us-west-2.rds.amazonaws.com:5432/tiptap
TIPTAP_LICENSE_KEY=your_tiptap_license_key
TIPTAP_JWT_SECRET=your_jwt_secret
TIPTAP_API_SECRET=huhuhaha

# VPC Configuration (if peering enabled)
TARGET_VPC_ID=vpc-xxxxxxxxx
```

### 4. AWS OIDC and IAM Role for Digger (Managed by Terraform)

The AWS OpenID Connect (OIDC) provider and the specific IAM Role (`DiggerGithubActionsRole`) that Digger will assume via GitHub Actions are now defined in the `oidc-digger-setup.tf` file. This Terraform configuration handles:

*   **Creation of the IAM OIDC Provider**: Connects AWS IAM with GitHub Actions.
*   **Definition of a Trust Policy**: Specifies that only GitHub Actions running in *your* designated repository (defined by `local.github_repository_path` in `oidc-digger-setup.tf`) can assume the role.
*   **Creation of the `DiggerGithubActionsRole` IAM Role**: This is the role Digger's GitHub Action will assume.
*   **Creation of `DiggerExecutionPolicy`**: An IAM policy attached to the `DiggerGithubActionsRole`. **Initially, this policy grants broad `Allow Action: "*", Resource: "*"` permissions. It is CRITICAL to refine this policy to least privilege after initial setup and testing.**

When you apply `oidc-digger-setup.tf`, it will create these resources. The output `digger_github_actions_role_arn` should be used for the `AWS_ROLE_ARN` GitHub secret.

The manual AWS CLI commands previously listed here for creating the OIDC provider and role are now accomplished by running `terraform apply` on `oidc-digger-setup.tf`.

**Action Required**: 
1. Ensure `oidc-digger-setup.tf` is in your project (likely at the root, alongside `backend-setup.tf`).
2. **Crucially, edit `oidc-digger-setup.tf` and update the `local.github_repository_path` variable to point to your GitHub repository (e.g., `"MyOrg/MyRepo"`).**
3. Apply the configuration using `terraform apply` (as shown in Step 1).
4. Use the outputted `digger_github_actions_role_arn` for your `AWS_ROLE_ARN` GitHub secret.

### 5. Create Digger Organization

1. Go to [digger.dev](https://digger.dev)
2. Sign up/login with your GitHub account
3. Create a new organization
4. Get your `DIGGER_ORG_ID` and `DIGGER_TOKEN` from the dashboard

### 6. Test the Setup

1. **Create a test PR** with a small change to any `.tf` file
2. **Check for automated plan**: Digger should automatically comment with the plan
3. **Test apply**: Comment `digger apply` on the PR to trigger apply
4. **Check concurrent execution**: Make changes to multiple modules to see parallel execution

## Usage

### Basic Commands

Comment these on PRs to trigger actions:

```bash
# Plan infrastructure changes
digger plan

# Apply changes
digger apply

# Plan specific project
digger plan tiptap-terraform-prod

# Apply specific project  
digger apply tiptap-terraform-stage

# Get help
digger help
```

### Environment Management

The workflow automatically determines environment based on branch:
- `main` branch → Production environment (`prod.tfvars`)
- Other branches → Staging environment (`stage.tfvars`)

### Advanced Features

#### Drift Detection
Digger will automatically check for drift daily at 6 AM UTC and create issues if detected.

#### Policy Enforcement
Uncomment the OPA policies in `digger.yml` to enforce rules like:
- Prevent EKS cluster deletion without approval
- Block VPC modifications in production

#### Concurrent Execution
Digger automatically runs independent infrastructure changes in parallel, significantly speeding up deployments.

## Project Structure

```
├── .github/
│   └── workflows/
│       └── digger.yml              # GitHub Actions workflow
├── scispace-infra/                # <--- CHANGED
│   ├── environments/
│   │   ├── prod.tfvars            # Production configuration
│   │   └── stage.tfvars           # Staging configuration
│   ├── *.tf                       # Your Terraform files for scispace-infra
│   └── versions.tf                # Updated with S3 backend (ss-terraform-state-us-west-2)
├── infra_prerequisites.tf         # Consolidated backend and OIDC setup (S3: ss-terraform-state-us-west-2)
└── digger.yml                     # Digger configuration (references scispace-infra)
```

## Troubleshooting

### State Lock Issues
```