#!/bin/bash

# Parse AWS credentials from the ~/.aws/credentials file
AWS_CREDENTIALS_FILE="$HOME/.aws/credentials"
AWS_CONFIG_FILE="$HOME/.aws/config"

if [ -f "$AWS_CREDENTIALS_FILE" ]; then
    AWS_ACCESS_KEY_ID=$(grep -m 1 'aws_access_key_id' "$AWS_CREDENTIALS_FILE" | awk '{print $3}')
    AWS_SECRET_ACCESS_KEY=$(grep -m 1 'aws_secret_access_key' "$AWS_CREDENTIALS_FILE" | awk '{print $3}')
else
    echo "AWS credentials file not found at $AWS_CREDENTIALS_FILE"
    exit 1
fi

if [ -f "$AWS_CONFIG_FILE" ]; then
    AWS_DEFAULT_REGION=$(grep -m 1 'region' "$AWS_CONFIG_FILE" | awk '{print $3}')
else
    echo "AWS config file not found at $AWS_CONFIG_FILE"
    exit 1
fi

# Export the parsed values as environment variables
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

echo "AWS environment variables set:"
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
echo "AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION"