#!/usr/bin/env bash

STACK_NAME=$1

echo "Deleting the CloudFormation stack $STACK_NAME"
aws cloudformation delete-stack \
    --stack-name $STACK_NAME
echo ""

if [[  -f .bucketconfig ]]; then
    source .bucketconfig
    echo "You have used the bucket '$S3_BUCKET_NAME' to host deployment assets.
If you do not use this bucket for other purposes, you might want to consider removing it."
fi 

echo ""
echo "####### WARNING ####### 
Destruction of the stack does not release the Dedicated Hosts allocated for this example. 
Go to https://console.aws.amazon.com/ec2/v2/#Hosts 24 hours after allocation to release the hosts and stop
being charged." 
