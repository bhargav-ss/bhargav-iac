# Aggregated View Server

This directory contains Terraform configuration for managing the infrastructure resources needed for the `agg-view-server` service.

## Resources

- ECR Repository: For storing Docker images of the service

## Usage

```bash
# Initialize Terraform
cd terraform/services/agg-view-server
terraform init -backend-config=../../../environment/dev/backend.tfvars

# Select workspace (environment)
terraform workspace select dev  # or create if it doesn't exist

# Plan changes
terraform plan -var-file=../../../environment/dev/terraform.tfvars

# Apply changes
terraform apply -var-file=../../../environment/dev/terraform.tfvars
```

## Outputs

- `ecr_repository_url`: The URL of the ECR repository (used for pushing Docker images)
- `ecr_repository_arn`: The ARN of the ECR repository

## Deployment

After applying the Terraform configuration, you can build and push your Docker image to the ECR repository:

```bash
# Build Docker image
docker build -t $ECR_REPOSITORY_URL:latest .

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL

# Push the image
docker push $ECR_REPOSITORY_URL:latest
``` 