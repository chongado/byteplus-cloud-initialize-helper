# BytePlus Cloud Initialize Helper

Use this skill when a user wants to create, review, update, or destroy a fresh
deployment of this package in their own BytePlus account by supplying:

- AK and SK
- project name
- app name

This skill orchestrates the existing package workflow instead of re-implementing
it:

- `scripts/bootstrap_app_deployment.sh`
- `terraform.sh`
- `scripts/deploy_welcome_app.sh`
- `scripts/destroy.py`

## What This Skill Does

This skill prepares and drives a full deployment workflow for a new customer app
on BytePlus Cloud:

1. collects or confirms the required inputs
2. writes `.env` and `terraform_script/var.tfvars`
3. runs Terraform init, validate, plan, and apply through `terraform.sh`
4. surfaces generated access artifacts and outputs
5. optionally runs the sample welcome web server post-provisioning workflow
6. supports a guarded destroy workflow

## Important Truths

- The current Terraform stack names infrastructure mainly from `project_name`
  and `environment`.
- `app_name` is stored as operator metadata in `.env` and is useful for
  follow-up app deployment steps, but it is not a native Terraform variable in
  this package.
- Deployable cloud resource names are derived from a sanitized form of
  `project_name`, replacing unsupported characters such as underscores with
  hyphens while keeping the original IAM project name unchanged.
- The sample welcome web server is not deployed by Terraform. It is a separate
  post-provisioning Kubernetes step.
- Destroy is not a plain `terraform destroy`. It must run through
  `./terraform.sh destroy`, which delegates to `scripts/destroy.py`.

## Required Inputs

- BytePlus access key
- BytePlus secret key
- project name
- app name
- whether the customer wants FileNAS enabled

Prefer project names that already use only letters, numbers, and hyphens, for
example `my-app-project`.

## Optional Inputs

- environment, default `uat`
- region, default `ap-southeast-1`
- FileNAS permission group name or ID
- welcome web server deployment intent

## Anti-Triggers

Do not use this skill when:

- the user only wants a welcome web server-only change
- the user only wants Terraform debugging for an existing broken state
- the user wants a generic reusable Terraform module redesign

## Recommended Workflow

### 1. Prepare Inputs

Collect:

- `ak`
- `sk`
- `project_name`
- `app_name`
- `use_filenas = yes|no`

Ask the customer explicitly whether FileNAS should be enabled before
bootstrapping local config. Do not assume a default answer on their behalf.

If the customer wants FileNAS, also collect:

- `enable_filenas = true`
- either `nas_permission_group_id`
- or `nas_permission_group_name`

If the customer does not want FileNAS, set:

- `enable_filenas = false`

### 2. Bootstrap Local Config

Run:

```bash
./scripts/bootstrap_app_deployment.sh \
  --ak '<AK>' \
  --sk '<SK>' \
  --project-name '<PROJECT_NAME>' \
  --app-name '<APP_NAME>' \
  --disable-filenas
```

Optional flags:

```bash
--environment uat
--region ap-southeast-1
--enable-filenas
--disable-filenas
--nas-permission-group-name default
--force
```

This writes:

- `.env`
- `terraform_script/var.tfvars`

The bootstrap flow also records sanitized naming helpers in `.env` for later
steps that need cloud-safe or Kubernetes-safe names.

### 3. Run Infrastructure Deployment

Run:

```bash
./terraform.sh init -lockfile=readonly
./terraform.sh validate
./terraform.sh plan
```

Ask for confirmation before:

```bash
./terraform.sh apply
```

### 4. Surface Artifacts

After apply, show:

- `./terraform.sh output`
- bastion IP
- generated kubeconfig path
- generated VPN profile path
- generated PEM paths

If SSH key handling is needed for operator access, collect or provide it after
Terraform deployment as part of the access workflow, not as a bootstrap input
to this skill. Bastion access is based on the generated Terraform key material.

Resource names and generated filenames may use a sanitized project-name prefix
when the original `project_name` contains unsupported characters.

### 5. Optional Welcome Web Server Deployment

Use this only if the user explicitly wants a sample web server after
infrastructure creation.

Run:

```bash
./scripts/deploy_welcome_app.sh check
./scripts/deploy_welcome_app.sh deploy
./scripts/deploy_welcome_app.sh status
```

Only proceed when:

- cluster reachability exists through VPN or bastion
- `kubectl` is available
- the welcome page HTML file is present

### 6. Destroy Workflow

Always review first:

```bash
./terraform.sh plan -destroy
```

Then destroy only with explicit confirmation:

```bash
./terraform.sh destroy
```

For unattended, already-approved execution:

```bash
./terraform.sh destroy -auto-approve
```

## Safety Rules

- Never place AK or SK into `terraform_script/var.tfvars`
- Never place private SSH keys into `terraform_script/var.tfvars`
- Treat `.env`, `terraform_script/generated/`, and `.terraform-teardown/` as sensitive
- Ask for confirmation before `apply`
- Ask for confirmation before `destroy`
- Be explicit that deployable resource names may differ slightly from the raw
  `project_name` when unsupported characters are normalized
- Be explicit that the sample welcome web server does not come back
  automatically after `destroy` plus `apply`; it must be redeployed

## Output Contract

When this skill finishes a deploy-oriented run, return:

- whether bootstrap files were written
- whether Terraform init, validate, plan, and apply succeeded
- key output values
- generated artifact paths
- whether the sample welcome web server was deployed
- any blockers that still require operator action

When this skill finishes a destroy-oriented run, return:

- whether the destroy plan was reviewed
- whether destroy succeeded
- whether `.terraform-teardown/` contains recovery material

## Implementation Note

This skill is intentionally package-specific. It is designed to operate this
repo safely by reusing the existing wrapper scripts instead of bypassing them
with raw Terraform commands.
