#!/usr/bin/env bash
set -euo pipefail
umask 077

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command_name="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi
resolved_nas_permission_group_id=""

load_local_env() {
  if [[ -f "$root_dir/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$root_dir/.env"
    set +a
  fi

  if [[ -n "${AK:-}" && -z "${BYTEPLUS_ACCESS_KEY:-}" ]]; then
    export BYTEPLUS_ACCESS_KEY="$AK"
  fi
  if [[ -n "${SK:-}" && -z "${BYTEPLUS_SECRET_KEY:-}" ]]; then
    export BYTEPLUS_SECRET_KEY="$SK"
  fi

  if [[ -n "${BYTEPLUS_ACCESS_KEY:-}" && -z "${TF_VAR_byteplus_access_key:-}" ]]; then
    export TF_VAR_byteplus_access_key="$BYTEPLUS_ACCESS_KEY"
  fi
  if [[ -n "${BYTEPLUS_SECRET_KEY:-}" && -z "${TF_VAR_byteplus_secret_key:-}" ]]; then
    export TF_VAR_byteplus_secret_key="$BYTEPLUS_SECRET_KEY"
  fi
}

read_tfvars_value() {
  local key="$1"
  local tfvars_file="$root_dir/terraform_script/var.tfvars"
  local line value

  if [[ ! -f "$tfvars_file" ]]; then
    return 0
  fi

  line="$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$tfvars_file" | tail -n 1 || true)"
  if [[ -z "$line" ]]; then
    return 0
  fi

  line="${line%%#*}"
  value="${line#*=}"
  value="$(printf '%s' "$value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

  if [[ $value == \"*\" && $value == *\" ]]; then
    value="${value:1:${#value}-2}"
  fi

  printf '%s' "$value"
}

get_input_value() {
  local key="$1"
  local default_value="${2:-}"
  local env_key="TF_VAR_${key}"
  local value="${!env_key:-}"

  if [[ -n "$value" ]]; then
    printf '%s' "$value"
    return 0
  fi

  value="$(read_tfvars_value "$key")"
  if [[ -n "$value" ]]; then
    printf '%s' "$value"
    return 0
  fi

  printf '%s' "$default_value"
}

resolve_filenas_permission_group_id() {
  local enable_filenas permission_group_id permission_group_name region query match_count

  enable_filenas="$(get_input_value enable_filenas false)"
  if [[ "$enable_filenas" != "true" ]]; then
    return 0
  fi

  permission_group_id="$(get_input_value nas_permission_group_id)"
  if [[ -n "$permission_group_id" ]]; then
    resolved_nas_permission_group_id="$permission_group_id"
    return 0
  fi

  permission_group_name="$(get_input_value nas_permission_group_name)"
  if [[ -z "$permission_group_name" ]]; then
    return 0
  fi

  if [[ "$permission_group_name" == *"'"* ]]; then
    echo "Permission group names containing single quotes are not supported by terraform.sh auto-resolution." >&2
    exit 1
  fi

  if ! command -v bp >/dev/null 2>&1; then
    echo "bp CLI is required to resolve nas_permission_group_name automatically." >&2
    exit 1
  fi

  region="$(get_input_value region ap-southeast-1)"
  query="Result.PermissionGroups[?PermissionGroupName=='${permission_group_name}']"
  match_count="$(
    bp filenas DescribePermissionGroups \
      --region "$region" \
      --FileSystemType Extreme \
      --query "length(${query})" \
      --output text
  )"

  if [[ "$match_count" == "0" ]]; then
    echo "No FileNAS permission group named '${permission_group_name}' was found in region '${region}'." >&2
    exit 1
  fi
  if [[ "$match_count" != "1" ]]; then
    echo "Expected exactly one FileNAS permission group named '${permission_group_name}' in region '${region}', found ${match_count}." >&2
    exit 1
  fi

  permission_group_id="$(
    bp filenas DescribePermissionGroups \
      --region "$region" \
      --FileSystemType Extreme \
      --query "${query}.PermissionGroupId | [0]" \
      --output text
  )"

  if [[ -z "$permission_group_id" || "$permission_group_id" == "None" || "$permission_group_id" == "null" ]]; then
    echo "Resolved FileNAS permission group '${permission_group_name}' but did not receive a usable ID." >&2
    exit 1
  fi

  resolved_nas_permission_group_id="$permission_group_id"
  echo "Resolved nas_permission_group_id from FileNAS permission group '${permission_group_name}'." >&2
}

load_local_env
# Terraform preserves the modes of existing state files. Normalize states that
# were created before this wrapper was introduced; never print their contents.
for state_file in "$root_dir"/terraform_script/*.tfstate "$root_dir"/terraform_script/*.tfstate.backup; do
  if [[ -f "$state_file" ]]; then chmod 600 "$state_file"; fi
done

case "$command_name" in
  init|validate|fmt|output|show|state|providers|version)
    exec terraform -chdir="$root_dir/terraform_script" "$command_name" "$@"
    ;;
  destroy)
    # Required VKE add-ons cannot be deleted independently. The helper reviews
    # the plan before changing state, then delegates their cleanup to the cluster.
    exec python3 "$root_dir/scripts/destroy.py" "$@"
    ;;
  plan|apply|import|refresh)
    resolve_filenas_permission_group_id
    if [[ -n "$resolved_nas_permission_group_id" ]]; then
      exec terraform -chdir="$root_dir/terraform_script" "$command_name" -var-file=var.tfvars "-var=nas_permission_group_id=${resolved_nas_permission_group_id}" "$@"
    fi
    exec terraform -chdir="$root_dir/terraform_script" "$command_name" -var-file=var.tfvars "$@"
    ;;
  *)
    cat <<'USAGE'
Usage: ./terraform.sh <command> [Terraform options]

export BYTEPLUS_ACCESS_KEY=...   # obtain securely; never commit credentials
export BYTEPLUS_SECRET_KEY=...
./terraform.sh init
./terraform.sh validate
./terraform.sh plan
./terraform.sh apply

# Optional FileNAS convenience:
# - set enable_filenas = true
# - either set nas_permission_group_id directly, or
# - set nas_permission_group_name and let terraform.sh resolve the ID via bp CLI

# Review and destroy the deployment (including the app_project project):
./terraform.sh plan -destroy
./terraform.sh destroy
# For already-authorized unattended execution:
./terraform.sh destroy -auto-approve

The wrapper always runs in terraform_script/, loads var.tfvars for plan/apply/destroy/import,
and uses a restrictive umask for state and access artifacts.
Pass extra options after the command (for example, plan -out=generated/terraform.tfplan).
To apply a saved plan, use native Terraform:
  terraform -chdir=terraform_script apply generated/terraform.tfplan
Destroy removes resources owned by the current state, including the project
and generated access files. Preserve the state when maintaining a deployment.
Destroy requires Python 3 and saves a private backup in .terraform-teardown/.
USAGE
    ;;
esac
