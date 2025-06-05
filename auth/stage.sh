#! /bin/bash

# This script is used to get session token to perform terraform operations / k8s operations

# Get AWS session token (necessary for both k8s and terraform)
eval $(aws sts get-session-token --serial-number arn:aws:iam::249531194221:mfa/1Password --token-code $(op item get "Amazon Typeset" --field type=otp --format json | jq -r .totp) --output json --profile stage | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId); export AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey); export AWS_SESSION_TOKEN=\(.SessionToken)"')

# Check if user wants to get authenticated for k8s or terraform via argument - default is terraform
if [ "$1" = "k8s" ]; then
    # Get cluster name from argument
    aws eks update-kubeconfig --name $2 --region us-west-2
fi
