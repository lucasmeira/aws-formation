#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
AMI_ID="${AMI_ID:-ami-0c02fb55956c7d316}"         # Amazon Linux 2 AMI (override via env)
KEY_NAME="${KEY_NAME:-my-key-pair}"                # EC2 key pair name for SSH access
SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-sg-xxxxxxxx}" # Security group to attach
SUBNET_ID="${SUBNET_ID:-subnet-xxxxxxxx}"          # Subnet where the instance will launch
AWS_REGION="${AWS_REGION:-us-east-1}"              # Target AWS region

# Launch the EC2 instance and capture its ID
# --instance-type: free-tier eligible | --query: extracts only the instance ID
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$AWS_REGION" \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --subnet-id "$SUBNET_ID" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "Launched instance: $INSTANCE_ID"

# Wait until the instance reaches the 'running' state
aws ec2 wait instance-running \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID"

echo "Instance $INSTANCE_ID is running."
