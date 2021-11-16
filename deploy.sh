#!/usr/bin/env bash

STACK_NAME=$1

if ! aws cloudformation describe-stacks --stack-name $STACK_NAME &> /dev/null ; then
    echo "No CloudFormation stack with name \"$STACK_NAME\" exist, creating ..."
    aws cloudformation create-stack \
        --stack-name $1 \
        --template-body "file://templates/main.yaml" \
        --parameters "file://parameters.json" \
        --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM"
else
    echo "Updating CloudFormation stack $STACK_NAME ..."
    aws cloudformation update-stack \
        --stack-name $1 \
        --template-body "file://templates/main.yaml" \
        --parameters "file://parameters.json" \
        --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM"
fi
