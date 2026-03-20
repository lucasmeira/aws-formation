#!/usr/bin/env bash
set -euo pipefail

ROLE_ARN="${ROLE_ARN:-${1:-}}"
ROLE_SESSION_NAME="${ROLE_SESSION_NAME:-${2:-}}"
PROFILE="${PROFILE:-${3:-}}"

if [[ -z "$ROLE_ARN" || -z "$ROLE_SESSION_NAME" || -z "$PROFILE" ]]; then
  echo "Usage: $0 <role-arn> <role-session-name> <profile>"
  echo "       or set ROLE_ARN, ROLE_SESSION_NAME, PROFILE env vars"
  exit 1
fi

CREDS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$ROLE_SESSION_NAME" \
  --profile "$PROFILE" \
  --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
  --output text)

echo $CREDS

AWS_ACCESS_KEY_ID=$(echo "$CREDS" | awk '{print $1}')
AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | awk '{print $2}')
AWS_SESSION_TOKEN=$(echo "$CREDS" | awk '{print $3}')

echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
