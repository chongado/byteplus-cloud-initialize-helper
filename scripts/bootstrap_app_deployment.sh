#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$root_dir/.env"
tfvars_file="$root_dir/terraform_script/var.tfvars"

ak=""
sk=""
project_name=""
app_name=""
environment="uat"
region="ap-southeast-1"
enable_filenas=""
nas_permission_group_id=""
nas_permission_group_name=""
vke_version="1.36"
bastion_image_id="image-yde3i2v6bwbhccnzezc6"
node_image_id="image-yd7m36o070bhccsa6p6o"
force="false"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/bootstrap_app_deployment.sh \
    --ak <BYTEPLUS_AK> \
    --sk <BYTEPLUS_SK> \
    --project-name <byteplus-project-name> \
    --app-name <application-name> \
    [--environment uat] \
    [--region ap-southeast-1] \
    [--enable-filenas] \
    [--disable-filenas] \
    [--nas-permission-group-id <id>] \
    [--nas-permission-group-name <name>] \
    [--force]

What this writes:
  - .env
  - terraform_script/var.tfvars

Notes:
  - The current Terraform package uses project_name and environment directly.
  - app_name is stored as operator metadata in .env and can be used as the
    default naming seed for follow-up app deployment steps.
  - Prefer project_name values that already use only letters, numbers, and
    hyphens. Example: my-app-project
  - FileNAS is an explicit customer choice. Pass either --enable-filenas or
    --disable-filenas, or run interactively and answer the prompt.
  - Deployable cloud resource names are derived from a sanitized project name,
    replacing unsupported characters such as underscores with hyphens.
  - If FileNAS is enabled and no permission group input is provided, this
    script defaults nas_permission_group_name to "default".
USAGE
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

hcl_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

sanitize_resource_name() {
  printf '%s' "$1" | sed -E 's/[^[:alnum:]-]+/-/g; s/^-+//; s/-+$//'
}

sanitize_dns_label() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ak)
      ak="${2:-}"
      shift 2
      ;;
    --sk)
      sk="${2:-}"
      shift 2
      ;;
    --project-name)
      project_name="${2:-}"
      shift 2
      ;;
    --app-name)
      app_name="${2:-}"
      shift 2
      ;;
    --environment)
      environment="${2:-}"
      shift 2
      ;;
    --region)
      region="${2:-}"
      shift 2
      ;;
    --enable-filenas)
      enable_filenas="true"
      shift
      ;;
    --disable-filenas)
      enable_filenas="false"
      shift
      ;;
    --nas-permission-group-id)
      nas_permission_group_id="${2:-}"
      shift 2
      ;;
    --nas-permission-group-name)
      nas_permission_group_name="${2:-}"
      shift 2
      ;;
    --vke-version)
      vke_version="${2:-}"
      shift 2
      ;;
    --bastion-image-id)
      bastion_image_id="${2:-}"
      shift 2
      ;;
    --node-image-id)
      node_image_id="${2:-}"
      shift 2
      ;;
    --force)
      force="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$ak" ]] || die "--ak is required."
[[ -n "$sk" ]] || die "--sk is required."
[[ -n "$project_name" ]] || die "--project-name is required."
[[ -n "$app_name" ]] || die "--app-name is required."

if [[ -z "$enable_filenas" ]]; then
  if [[ -t 0 ]]; then
    read -r -p "Use FileNAS for this deployment? [y/N]: " filenas_choice
    filenas_choice="$(printf '%s' "$filenas_choice" | tr '[:upper:]' '[:lower:]')"
    case "$filenas_choice" in
      y|yes)
        enable_filenas="true"
        ;;
      n|no|"")
        enable_filenas="false"
        ;;
      *)
        die "Please answer yes or no for the FileNAS choice."
        ;;
    esac
  else
    die "FileNAS choice is required. Pass either --enable-filenas or --disable-filenas."
  fi
fi

resource_name_project="$(sanitize_resource_name "$project_name")"
resource_prefix="${resource_name_project}-${environment}"
app_name_slug="$(sanitize_dns_label "$app_name")"

[[ -n "$resource_name_project" ]] || die "--project-name must contain at least one letter or number."
[[ -n "$app_name_slug" ]] || die "--app-name must contain at least one lowercase letter or number after sanitization."

if [[ "$resource_name_project" != "$project_name" ]]; then
  printf 'Warning: project_name "%s" contains characters that are unsafe for some BytePlus resource names.\n' "$project_name" >&2
  printf 'Using sanitized deployable resource prefix "%s". Prefer letters, numbers, and hyphens in future project names.\n' "$resource_name_project" >&2
fi

if [[ "$enable_filenas" == "true" && -z "$nas_permission_group_id" && -z "$nas_permission_group_name" ]]; then
  nas_permission_group_name="default"
fi

if [[ "$force" != "true" ]]; then
  [[ ! -e "$env_file" ]] || die "$env_file already exists. Re-run with --force to overwrite it."
  [[ ! -e "$tfvars_file" ]] || die "$tfvars_file already exists. Re-run with --force to overwrite it."
fi

mkdir -p "$(dirname -- "$tfvars_file")"

cat >"$env_file" <<EOF
# Generated by scripts/bootstrap_app_deployment.sh
AK=$ak
SK=$sk
APP_NAME=$app_name
APP_NAME_SLUG=$app_name_slug
PROJECT_NAME=$project_name
RESOURCE_NAME_PROJECT=$resource_name_project
RESOURCE_NAME_PREFIX=$resource_prefix
DEPLOYMENT_ENVIRONMENT=$environment
BYTEPLUS_REGION=$region
EOF
chmod 600 "$env_file"

cat >"$tfvars_file" <<EOF
# Generated by scripts/bootstrap_app_deployment.sh
# Review all values before running ./terraform.sh apply.
region       = $(hcl_quote "$region")
project_name = $(hcl_quote "$project_name")
project_id   = $(hcl_quote "$project_name")
environment  = $(hcl_quote "$environment")

enable_filenas            = $enable_filenas
nas_permission_group_id   = $(hcl_quote "$nas_permission_group_id")
nas_permission_group_name = $(hcl_quote "$nas_permission_group_name")

vke_version      = $(hcl_quote "$vke_version")
bastion_image_id = $(hcl_quote "$bastion_image_id")
node_image_id    = $(hcl_quote "$node_image_id")
EOF
chmod 600 "$tfvars_file"

cat <<EOF
Wrote:
  - $env_file
  - $tfvars_file

Next steps:
  1. Review terraform_script/var.tfvars carefully.
  2. Run ./terraform.sh init -lockfile=readonly
  3. Run ./terraform.sh validate
  4. Run ./terraform.sh plan
  5. Run ./terraform.sh apply

Optional welcome app follow-up:
  - Run ./scripts/deploy_welcome_app.sh check
  - Run ./scripts/deploy_welcome_app.sh deploy

Destroy workflow:
  - Run ./terraform.sh plan -destroy
  - Run ./terraform.sh destroy

Note:
  app_name is stored in .env as operator metadata, while the simple welcome app
  deployment uses a sanitized lowercase form as the default workload naming
  seed. Terraform keeps the original project_name for the IAM project and uses
  the sanitized prefix "$resource_prefix" for deployable cloud resource names.
EOF
