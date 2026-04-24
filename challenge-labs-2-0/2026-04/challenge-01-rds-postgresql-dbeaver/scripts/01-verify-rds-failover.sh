#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  01-verify-rds-failover.sh --db-instance-id <id> [options]

Options:
  --db-instance-id <id>      RDS DB instance identifier. Required.
                             RDS endpoint hostnames are accepted and normalized.
  --baseline-file <path>     Baseline file path. Default: ./rds-failover-baseline.env
  --save-baseline            Save current primary/secondary zones before failover.
  --profile <profile>        AWS CLI profile.
  --region <region>          AWS region.
  -h, --help                 Show this help.

Flow:
  # 1) Before reboot with failover
  ./01-verify-rds-failover.sh --db-instance-id dl2-rds-postgres-lab --save-baseline

  # 2) Trigger reboot with failover in the console or AWS CLI.
  # 3) After failover completes
  ./01-verify-rds-failover.sh --db-instance-id dl2-rds-postgres-lab

Output:
  The script prints a colored summary with the DB instance name, current primary zone,
  current standby zone, and whether the primary moved to the saved standby zone.
  Set NO_COLOR=1 to disable colors or FORCE_COLOR=1 to force colors in non-TTY output.
USAGE
}

DB_INSTANCE_ID=""
BASELINE_FILE="./rds-failover-baseline.env"
SAVE_BASELINE=false
AWS_PROFILE=""
AWS_REGION=""

if [[ -z "${NO_COLOR:-}" && ( -t 1 || -n "${FORCE_COLOR:-}" ) ]]; then
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RED=$'\033[31m'
  ORANGE=$'\033[38;5;208m'
  BLUE=$'\033[34m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  GREEN=""
  YELLOW=""
  RED=""
  ORANGE=""
  BLUE=""
  BOLD=""
  RESET=""
fi

print_title() {
  printf '%b%s%b\n' "$BOLD$BLUE" "$1" "$RESET"
}

print_detail() {
  local label="$1"
  local value="$2"

  printf '  %b%s%b %s\n' "$BLUE" "$label:" "$RESET" "$value"
}

print_success() {
  printf '%b%s%b\n' "$GREEN" "$1" "$RESET"
}

print_warning() {
  printf '%b%s%b\n' "$YELLOW" "$1" "$RESET"
}

print_pending() {
  printf '%b%s%b\n' "$ORANGE" "$1" "$RESET"
}

print_error() {
  printf '%bERROR:%b %s\n' "$RED" "$RESET" "$1" >&2
}

require_option_value() {
  local option="$1"
  local value="${2-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    print_error "Missing value for option: $option"
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db-instance-id)
      require_option_value "$1" "${2-}"
      DB_INSTANCE_ID="$2"
      shift 2
      ;;
    --baseline-file)
      require_option_value "$1" "${2-}"
      BASELINE_FILE="$2"
      shift 2
      ;;
    --save-baseline)
      SAVE_BASELINE=true
      shift
      ;;
    --profile)
      require_option_value "$1" "${2-}"
      AWS_PROFILE="$2"
      shift 2
      ;;
    --region)
      require_option_value "$1" "${2-}"
      AWS_REGION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$DB_INSTANCE_ID" ]]; then
  print_error "Missing required option: --db-instance-id"
  usage >&2
  exit 2
fi

ORIGINAL_DB_INSTANCE_ID="$DB_INSTANCE_ID"
NORMALIZED_DB_INSTANCE_ID=""

if [[ "$DB_INSTANCE_ID" == *.* ]]; then
  DB_INSTANCE_ID="${DB_INSTANCE_ID%%.*}"
  NORMALIZED_DB_INSTANCE_ID="$DB_INSTANCE_ID"
fi

if [[ ! "$DB_INSTANCE_ID" =~ ^[A-Za-z][A-Za-z0-9-]*$ || "$DB_INSTANCE_ID" == *--* || "$DB_INSTANCE_ID" == *- ]]; then
  print_error "Invalid DB instance identifier: $ORIGINAL_DB_INSTANCE_ID"
  printf '%b%s%b\n' "$RED" "Use the DB instance identifier, for example: database-1-multi-az." "$RESET" >&2
  printf '%b%s%b\n' "$RED" "Identifiers must begin with a letter, contain only ASCII letters, digits, and hyphens, and must not end with a hyphen or contain two consecutive hyphens." "$RESET" >&2
  if [[ "$ORIGINAL_DB_INSTANCE_ID" == *.* ]]; then
    printf '%b%s%b\n' "$RED" "Endpoint hostnames are accepted only when the first DNS label is a valid DB instance identifier." "$RESET" >&2
  fi
  exit 2
fi

if ! command -v aws >/dev/null 2>&1; then
  print_error "aws CLI was not found in PATH"
  exit 127
fi

describe_instance() {
  local aws_cmd=(aws)

  if [[ -n "$AWS_PROFILE" ]]; then
    aws_cmd+=(--profile "$AWS_PROFILE")
  fi

  if [[ -n "$AWS_REGION" ]]; then
    aws_cmd+=(--region "$AWS_REGION")
  fi

  "${aws_cmd[@]}" rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,MultiAZ,AvailabilityZone,SecondaryAvailabilityZone,Endpoint.Address]' \
    --output text
}

read -r INSTANCE_NAME INSTANCE_STATUS MULTI_AZ CURRENT_PRIMARY_ZONE CURRENT_SECONDARY_ZONE ENDPOINT < <(describe_instance)

if [[ "$CURRENT_SECONDARY_ZONE" == "None" ]]; then
  CURRENT_SECONDARY_ZONE=""
fi

if [[ -n "$NORMALIZED_DB_INSTANCE_ID" ]]; then
  print_warning "Endpoint hostname received. Using DB instance identifier: $NORMALIZED_DB_INSTANCE_ID"
fi

if [[ "$SAVE_BASELINE" == "true" ]]; then
  cat > "$BASELINE_FILE" <<EOF
DB_INSTANCE_ID=$INSTANCE_NAME
BASELINE_PRIMARY_ZONE=$CURRENT_PRIMARY_ZONE
BASELINE_SECONDARY_ZONE=$CURRENT_SECONDARY_ZONE
BASELINE_ENDPOINT=$ENDPOINT
EOF

  print_title "RDS failover baseline saved"
  print_success "Baseline captured before failover. Reboot with failover, then run this script again."
  print_detail "Baseline file" "$BASELINE_FILE"
  print_detail "DB instance" "$INSTANCE_NAME"
  print_detail "Status" "$INSTANCE_STATUS"
  print_detail "Multi-AZ" "$MULTI_AZ"
  print_detail "Current primary AZ" "$CURRENT_PRIMARY_ZONE"
  print_detail "Current standby AZ" "${CURRENT_SECONDARY_ZONE:-not-configured}"
  print_detail "Endpoint" "$ENDPOINT"
  exit 0
fi

print_title "RDS failover verification"
print_detail "DB instance" "$INSTANCE_NAME"
print_detail "Status" "$INSTANCE_STATUS"
print_detail "Multi-AZ" "$MULTI_AZ"
print_detail "Current primary AZ" "$CURRENT_PRIMARY_ZONE"
print_detail "Current standby AZ" "${CURRENT_SECONDARY_ZONE:-not-configured}"
print_detail "Endpoint" "$ENDPOINT"

if [[ "$MULTI_AZ" != "True" ]]; then
  print_warning "Failover check: not applicable"
  print_warning "This DB instance is not Multi-AZ, so there is no standby AZ to promote."
  exit 1
fi

if [[ ! -f "$BASELINE_FILE" ]]; then
  print_warning "Failover check: unknown"
  print_warning "Baseline file not found. Run with --save-baseline before rebooting with failover."
  exit 1
fi

# shellcheck disable=SC1090
source "$BASELINE_FILE"

print_detail "Baseline primary AZ" "$BASELINE_PRIMARY_ZONE"
print_detail "Baseline standby AZ" "${BASELINE_SECONDARY_ZONE:-not-configured}"

if [[ -z "${BASELINE_SECONDARY_ZONE:-}" ]]; then
  print_warning "Failover check: unknown"
  print_warning "The baseline did not include a standby AZ, so the failover target cannot be verified."
  exit 1
fi

if [[ "$CURRENT_PRIMARY_ZONE" == "$BASELINE_SECONDARY_ZONE" ]]; then
  print_success "Failover check: passed"
  print_success "Primary is now running in the previous standby AZ: $BASELINE_SECONDARY_ZONE."
  exit 0
fi

print_pending "Failover check: not yet detected"
print_pending "Current primary AZ is still $CURRENT_PRIMARY_ZONE. Expected it to move to the saved standby AZ: $BASELINE_SECONDARY_ZONE."
exit 1
