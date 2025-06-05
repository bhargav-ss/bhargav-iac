#!/bin/bash

# Exit on any error
set -e

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
AWS_REGION=$(aws configure get region)

# ECR Registry URL
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}

# Build and push backend
echo "Building backend image..."
docker build -t ${ECR_URL}/apps-backend:latest ../apps/backend-service
echo "Pushing backend image..."
docker push ${ECR_URL}/apps-backend:latest

# Build and push frontend
echo "Building frontend image..."
docker build -t ${ECR_URL}/apps-frontend:latest ../apps/frontend-service
echo "Pushing frontend image..."
docker push ${ECR_URL}/apps-frontend:latest

echo "All images built and pushed successfully!" 