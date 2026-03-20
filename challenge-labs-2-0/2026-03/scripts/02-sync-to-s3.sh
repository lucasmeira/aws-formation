#!/usr/bin/env bash
set -euo pipefail

# Usage: ./02-sync-to-s3.sh <local-dir> <s3-uri>
# Example: ./02-sync-to-s3.sh ./dist s3://my-bucket/app/

# Validate required arguments
if [[ $# -ne 2 ]]; then
  echo "Error: missing arguments."
  echo "Usage: $0 <local-dir> <s3-uri>"
  echo "Example: $0 ./dist s3://my-bucket/app/"
  exit 1
fi

LOCAL_DIR="$1"   # Source directory to sync
S3_URI="$2"      # Destination S3 URI

# Ensure the local directory exists before syncing
if [[ ! -d "$LOCAL_DIR" ]]; then
  echo "Error: '$LOCAL_DIR' is not a directory or does not exist."
  exit 1
fi

echo "==> Dry run (no files will be transferred):"
aws s3 sync "$LOCAL_DIR" "$S3_URI" --dryrun   # Preview what would be uploaded/deleted

echo ""
echo "==> Starting real sync:"
aws s3 sync "$LOCAL_DIR" "$S3_URI"            # Perform the actual sync

echo "Sync complete: $LOCAL_DIR -> $S3_URI"
