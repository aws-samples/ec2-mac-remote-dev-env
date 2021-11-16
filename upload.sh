#!/usr/bin/env bash

# This script uploads all assets to an S3 bucket for deployment.
# The configuration of this bucket is read from user input in case no .bucketconfig file is found
# In case that the bucket does not exist, it will be created by the script.

S3_DEFAULT_BUCKET_NAME="ec2-mac-remote-dev-env-$(openssl rand -hex 8)"
S3_DEFAULT_BUCKET_REGION="us-east-2"
S3_DEFAULT_BUCKET_PREFIX=""

if [[ ! -f .bucketconfig ]]; then
    echo "Configuring S3 Bucket. "
    read -p "   Enter Bucket Name [\"$S3_DEFAULT_BUCKET_NAME\"]: " S3_BUCKET_NAME
    S3_BUCKET_NAME=${S3_BUCKET_NAME:-$S3_DEFAULT_BUCKET_NAME}
    read -p "   Enter Bucket Region [\"$S3_DEFAULT_BUCKET_REGION\"]: " S3_BUCKET_REGION
    S3_BUCKET_REGION=${S3_BUCKET_REGION:-$S3_DEFAULT_BUCKET_REGION}
    read -p "   Enter Bucket Prefix with trailing slash [\"$S3_DEFAULT_BUCKET_PREFIX\"]: " S3_BUCKET_PREFIX
    S3_BUCKET_PREFIX=${S3_BUCKET_PREFIX:-$S3_DEFAULT_BUCKET_PREFIX}
    {
        echo "S3_BUCKET_NAME=$S3_BUCKET_NAME"
        echo "S3_BUCKET_REGION=$S3_BUCKET_REGION"
        echo "S3_BUCKET_PREFIX=$S3_BUCKET_PREFIX"
    } > .bucketconfig
    echo "   Bucket configuration persisted to .bucketconfig file. Delete this file in case you want to reset"
fi 

source .bucketconfig

# Create the bucket if it doesn't exist and block all public access
if ! aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $S3_BUCKET_NAME does not exist and will be created."
    aws s3api create-bucket \
        --bucket $S3_BUCKET_NAME \
        --region $S3_BUCKET_REGION \
        --create-bucket-configuration LocationConstraint=$S3_BUCKET_REGION > /dev/null
    aws s3api put-public-access-block \
        --bucket $S3_BUCKET_NAME \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
fi


# Sync files to S3
echo "Uploading artifacts to bucket $S3_BUCKET_NAME"
aws s3 sync \
    --quiet \
    templates  \
    "s3://$(echo $S3_BUCKET_NAME/$S3_BUCKET_PREFIX/templates | tr -s /)" 
aws s3 sync \
    --quiet \
    submodules/quickstart-aws-vpc  \
    "s3://$(echo $S3_BUCKET_NAME/$S3_BUCKET_PREFIX/submodules/quickstart-aws-vpc | tr -s /)" 

aws s3 sync \
    --quiet \
    submodules/quickstart-microsoft-activedirectory  \
    "s3://$(echo $S3_BUCKET_NAME/$S3_BUCKET_PREFIX/submodules/quickstart-microsoft-activedirectory | tr -s /)" 

# Print Instructions on how to configure CloudFormation parameters
cat << EOF
Update your parameters.json file before running ./deploy.sh to match your bucket configuration:
    {
        "ParameterKey":"DS3BucketName",
        "ParameterValue":"$S3_BUCKET_NAME"
    },
    {
        "ParameterKey":"DS3KeyPrefix",
        "ParameterValue":"$S3_BUCKET_PREFIX"
    },
    {
        "ParameterKey":"DS3BucketRegion",
        "ParameterValue":"$S3_BUCKET_REGION"
    }
EOF

