#!/bin/bash
#
# Backend Setup Script
# Creates S3 bucket and DynamoDB table for Terraform remote state
#

set -euo pipefail

BUCKET_NAME="jokejolt-terraform-state-${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
TABLE_NAME="terraform-state-lock"
REGION="${AWS_REGION:-us-east-1}"

echo "Setting up Terraform remote state backend..."
echo "Bucket: ${BUCKET_NAME}"
echo "Table: ${TABLE_NAME}"
echo "Region: ${REGION}"
echo ""

# Create S3 bucket
echo "Creating S3 bucket..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "Bucket already exists: $BUCKET_NAME"
else
  if [ "$REGION" == "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi

  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "aws:kms"
          }
        }
      ]
    }'

  # Block public access
  aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  echo "S3 bucket created and configured."
fi

# Create DynamoDB table
echo ""
echo "Creating DynamoDB table for state locking..."
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
  echo "Table already exists: $TABLE_NAME"
else
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockId,AttributeType=S \
    --key-schema AttributeName=LockId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

  # Wait for table to be active
  echo "Waiting for DynamoDB table to be active..."
  aws dynamodb wait table-exists \
    --table-name "$TABLE_NAME" \
    --region "$REGION"

  echo "DynamoDB table created and active."
fi

echo ""
echo "Remote state backend setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit versions.tf and uncomment the backend 's3' block"
echo "2. Update the bucket name to: ${BUCKET_NAME}"
echo "3. Run: terraform init"
echo ""
