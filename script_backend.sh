#!/bin/bash

# Backend Setup Script using AWS CLI
# This script creates the S3 bucket and DynamoDB table for Terraform state management

echo "Setting up Terraform backend infrastructure in Tokyo region using AWS CLI..."

# Set the region and profile
REGION="ap-northeast-1"
AWS_PROFILE="stock"
BUCKET_NAME="prj-stock-terraform-state"
TABLE_NAME="prj-stock-terraform-lock"

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" \
  --profile "$AWS_PROFILE"

# Enable versioning for the bucket
echo "Enabling versioning for S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled \
  --profile "$AWS_PROFILE"

# Enable encryption for the bucket
echo "Enabling encryption for S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }' \
  --profile "$AWS_PROFILE"

# Block public access
echo "Blocking public access to S3 bucket..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration "
    BlockPublicAcls=true,
    IgnorePublicAcls=true,
    BlockPublicPolicy=true,
    RestrictPublicBuckets=true
  " \
  --profile "$AWS_PROFILE"

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" \
  --profile "$AWS_PROFILE"

# Wait for table to be created
echo "Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists \
  --table-name "$TABLE_NAME" \
  --region "$REGION"

echo ""
echo "✅ Backend setup completed successfully!"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $TABLE_NAME"
echo "Region: $REGION"
echo ""
echo "You can now use the backend for your Terraform configurations without -backend-config flag."