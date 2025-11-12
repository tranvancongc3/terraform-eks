#!/bin/bash

# Backend Setup Script using AWS CLI
# This script creates the S3 bucket and DynamoDB table for Terraform state management

echo "Setting up Terraform backend infrastructure in Tokyo region using AWS CLI..."

# Configuration
REGION="ap-northeast-1"
AWS_PROFILE="stock"
BUCKET_NAME="pic-kabu-terraform-state"
TABLE_NAME="pic-kabu-terraform-lock"

# Create S3 bucket if not exists
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api head-bucket --bucket "$BUCKET_NAME" --profile "$AWS_PROFILE" 2>/dev/null
if [ $? -ne 0 ]; then
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" \
    --profile "$AWS_PROFILE"
else
  echo "Bucket already exists. Skipping creation."
fi

# Enable versioning
echo "Enabling versioning for S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled \
  --profile "$AWS_PROFILE"

# Enable encryption
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

# Correct JSON format for public access block
echo "Blocking public access to S3 bucket..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }' \
  --profile "$AWS_PROFILE"

# Create DynamoDB table if not exists
echo "Checking DynamoDB table: $TABLE_NAME"
TABLE_EXISTS=$(aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" --profile "$AWS_PROFILE" 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Creating DynamoDB table: $TABLE_NAME"
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" \
    --profile "$AWS_PROFILE"
else
  echo "Table already exists. Skipping creation."
fi

# Wait for table (only if newly created)
aws dynamodb wait table-exists \
  --table-name "$TABLE_NAME" \
  --region "$REGION" \
  --profile "$AWS_PROFILE"

echo ""
echo "✅ Backend setup completed successfully!"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $TABLE_NAME"
echo "Region: $REGION"
echo ""
echo "You can now use the backend for your Terraform configurations."
