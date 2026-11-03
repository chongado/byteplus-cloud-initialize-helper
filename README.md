# BytePlus Cloud Initialize Helper

Release date: 2026-11-02.

This repository packages everything a user needs to create a fresh BytePlus
Cloud deployment from a single GitHub repo:

- Terraform infrastructure under `terraform_script/`
- the supported Terraform wrapper `terraform.sh`
- a bootstrap helper that writes `.env` and `terraform_script/var.tfvars`
- a simple welcome web server post-provisioning script
- the guarded destroy workflow
- a project-local agent skill under `.agents/skills/byteplus-cloud-initialize-helper/`

This repo is intended to be publishable and reusable. A clean published copy
should not include live credentials, Terraform state, private keys, kubeconfig
files, VPN profiles, generated artifacts, or teardown logs.

This repository ships example configuration only. Do not commit live
credentials, Terraform state, or generated access artifacts.

## Included Skill

The included skill lives at:

- `.agents/skills/byteplus-cloud-initialize-helper/SKILL.md`

The skill is package-specific. It is designed to guide or automate this repo's
deployment flow safely instead of generating an unrelated Terraform stack from
scratch.

## Architecture Diagram

This repository includes a publishable Archify diagram for public readers:

- [![BytePlus Cloud Initialize Helper Architecture](docs/architecture/byteplus-cloud-initialize-helper-deployed.svg)](docs/architecture/byteplus-cloud-initialize-helper-deployed.html)
- [Interactive architecture diagram](docs/architecture/byteplus-cloud-initialize-helper-deployed.html)

For GitHub, keep the committed diagram under `docs/architecture/` rather than
referencing the local `.archify/` working directory.

## Quick Start

If you are deploying this package from scratch, provide:

- BytePlus `AK`
- BytePlus `SK`
- a BytePlus `project_name`
- an `app_name`

If the Terraform infrastructure has already been deployed for you, skip this
section and start at `Step-By-Step Access After Deployment`.

Prefer `project_name` values that already use only letters, numbers, and
hyphens, for example `my-app-project`.

Deployable cloud resource names are derived from a sanitized form of
`project_name`, replacing unsupported characters such as underscores with
hyphens while keeping the IAM project name itself unchanged.

Then run:

```bash
./scripts/bootstrap_app_deployment.sh \
  --ak '<AK>' \
  --sk '<SK>' \
  --project-name '<PROJECT_NAME>' \
  --app-name '<APP_NAME>' \
  --disable-filenas
```

If the customer wants FileNAS, replace `--disable-filenas` with `--enable-filenas`.

Then review and deploy:

```bash
./terraform.sh init -lockfile=readonly
./terraform.sh validate
./terraform.sh plan
./terraform.sh apply
```

Optional welcome web server follow-up:

```bash
./scripts/deploy_welcome_app.sh check
./scripts/deploy_welcome_app.sh deploy
./scripts/deploy_welcome_app.sh status
```

Destroy workflow:

```bash
./terraform.sh plan -destroy
./terraform.sh destroy
```

## What This Repo Packages

This repo creates a new UAT environment in a user's own BytePlus account. It
includes the Terraform source, a sanitized configuration template, helper
scripts, the sample welcome web server deployment helper, and this operator guide.

This repo does not take ownership of any previously created environment unless
you explicitly import resources into the local Terraform state.

## What This Package Creates

By default, this package deploys the following in `ap-southeast-1`:

- one BytePlus IAM project
- one VPC
- three subnets across three zones
- NAT gateway and SNAT
- one private VKE cluster
- six VKE add-ons
- one workload node pool named `control`
- one SSL VPN setup
- one bastion host
- Elastic IP resources

The following remain outside the default deployment:

- worker node pool
- db node pool
- additional route table resources
- administrator IAM configuration

Optional but supported:

- FileNAS can be enabled through `terraform_script/var.tfvars`
- a simple welcome web server can be deployed after infrastructure creation by using `scripts/deploy_welcome_app.sh`

## Before You Start

Make sure all of the following are true before you run `plan` or `apply`:

1. You have `bash`, `terraform >= 1.9.8`, and `python3` installed.
2. Your machine can reach the Terraform Registry and BytePlus APIs.
3. The bastion can reach Ubuntu package repositories, Kubernetes package repositories, and GitHub during cloud-init.
4. Your BytePlus account has the required product activation, quotas, and permissions.
5. The image IDs, Kubernetes version, and instance types in this package are available in your target account and region.
6. The target project name is not already in use, unless you plan to import the existing project first.
7. If you plan to deploy the sample welcome web server from your local machine, your machine can reach the private VKE API through the VPN and has `kubectl` installed.

`terraform apply` creates billable resources.

## Important Operating Rules

- Use `terraform.sh` for normal operations. It always runs Terraform inside `terraform_script/`, automatically loads `terraform_script/var.tfvars` for `plan`, `apply`, `import`, `refresh`, and `destroy`, and will source a local `.env` file if present.
- This package uses a local backend at `terraform_script/terraform.tfstate`.
- Use one operator at a time with this package unless you first migrate to a shared backend with locking.
- Do not commit or distribute `terraform_script/terraform.tfstate`, `terraform_script/*.tfstate.backup`, `.terraform/`, `.terraform-teardown/`, or `terraform_script/generated/`.
- Do not commit or distribute `.env`, `terraform_script/var.tfvars`, `.archify/`, or any generated `.pem` and `.ovpn` files.
- Do not store API credentials or private keys in `terraform_script/var.tfvars`.

## Step-By-Step Deployment

## Step 1: Open The Package Directory

```bash
cd byteplus-cloud-initialize-helper
```

## Step 2: Create Your Working Variable File

Copy the example file and create your local working configuration:

```bash
cp terraform_script/var.tfvars.example terraform_script/var.tfvars
```

## Step 3: Edit `terraform_script/var.tfvars`

Review every value before deployment.

At minimum, confirm or update:

- `project_name`
- environment-specific naming values
- any image IDs
- any instance types
- any values specific to your target region or account

Notes:

- `project_id` is used only as the `PROJECT_ID` resource tag. It is not the internal ID of the project Terraform creates.
- Terraform generates the bastion and worker key pairs during deployment.
- Deployable cloud resource names and some generated filenames use a sanitized
  project-name prefix, so underscores in `project_name` become hyphens there.
- To enable FileNAS, set `enable_filenas = true`.
- For FileNAS mount targets, either set `nas_permission_group_id` directly or set `nas_permission_group_name` and let `terraform.sh` resolve the ID through the local `bp` CLI.
- Network CIDRs are defined in `terraform_script/variables.tf`.

## Step 4: Export Your BytePlus Credentials

Set credentials in your shell by using your approved secure method:

```bash
export BYTEPLUS_ACCESS_KEY=...
export BYTEPLUS_SECRET_KEY=...
```

Do not place these credentials in `terraform_script/var.tfvars`. If the package-local `.env` file contains `AK` and `SK`, `terraform.sh` will map them to the expected BytePlus environment variables automatically.

## Step 5: Initialize Terraform

```bash
./terraform.sh init -lockfile=readonly
```

Keep `terraform_script/.terraform.lock.hcl` and avoid `-upgrade` unless you intentionally want to retest provider behavior.

## Step 6: Validate The Configuration

```bash
./terraform.sh validate
```

If validation fails, fix the reported issue before continuing.

## Step 7: Review The Execution Plan

```bash
./terraform.sh plan
```

Check the plan carefully and confirm:

- the correct project name will be used
- the correct region and resource sizes are selected
- the expected network resources will be created
- no unexpected existing resource is being replaced

If the target BytePlus project already exists, import it first and re-run `plan` before `apply`.

## Step 8: Apply The Deployment

```bash
./terraform.sh apply
```

This step creates the project and infrastructure managed by this package.

## Step 9: Review The Outputs

After `apply` completes, inspect the outputs:

```bash
./terraform.sh output
```

Useful outputs include project, region, VPC, cluster, bastion, and generated file locations.

## FileNAS Support

When `enable_filenas = true`, the package creates two zonal FileNAS file systems
and the supported mount targets automatically through `terraform.sh`.

Set one of the following in `terraform_script/var.tfvars`:

- `nas_permission_group_id` if you want to pin the exact FileNAS permission group ID
- `nas_permission_group_name` if you want `terraform.sh` to resolve the ID automatically through the local `bp` CLI

For the current validated layout, Terraform manages one same-AZ mount target per
zonal FileNAS instance:

- `app_project-uat-nas` -> subnet `private_subnet_1a`
- `app_project-uat-nas-web` -> subnet `private_subnet_1b`

This matches the live FileNAS behavior observed during validation. The rejected
cross-zone mount-target combinations are no longer modeled.

From the wrapper point of view:

- `terraform.sh plan`
- `terraform.sh apply`

will automatically:

- load `.env` if present
- resolve `nas_permission_group_name` to `nas_permission_group_id` through `bp`
- pass the resolved permission group ID to Terraform

If `enable_filenas = false`, FileNAS resources are skipped entirely.

## Deploying The Welcome Web Server

This repo includes a simple `nginx`-based sample web server that serves a static
welcome page. Use it after the Terraform environment is ready and you can reach
the private VKE API through the VPN or from the bastion host.

Recommended deployment path:

1. Refresh the kubeconfig if it has expired:

```bash
./terraform.sh apply -replace=bytepluscc_vke_kubeconfig.devops_k8s_config
```

2. Copy `terraform_script/generated/devops_k8s_config` to `/home/devops/.kube/config` on the bastion if you will deploy from there.
3. Make sure `kubectl` is installed in the shell that can reach the cluster.
4. Run:

```bash
chmod +x scripts/deploy_welcome_app.sh
./scripts/deploy_welcome_app.sh check
./scripts/deploy_welcome_app.sh deploy
./scripts/deploy_welcome_app.sh status
```

The helper script:

- deploys a single-replica `nginx` web server
- creates a ConfigMap from `deploy/welcome-page/index.html`
- mounts the welcome page into the container
- creates a Service, defaulting to `LoadBalancer`
- prints Deployment, Service, and Pod status

Supported commands:

- `./scripts/deploy_welcome_app.sh help`
- `./scripts/deploy_welcome_app.sh check`
- `./scripts/deploy_welcome_app.sh deploy`
- `./scripts/deploy_welcome_app.sh status`
- `./scripts/deploy_welcome_app.sh delete`

Useful environment overrides:

- `KUBECONFIG`
- `WELCOME_NAMESPACE`
- `WELCOME_APP_NAME`
- `WELCOME_SERVICE_TYPE`
- `WELCOME_IMAGE`
- `WELCOME_HTML_FILE`

If `WELCOME_APP_NAME` contains unsupported Kubernetes name characters such as
underscores, the helper normalizes it to a lowercase hyphenated name before
creating resources.

Important notes before deployment:

- The helper does not bypass private-cluster networking. You still need VPN or bastion-based cluster reachability.
- The sample app is not managed by Terraform. It is a separate Kubernetes deployment step.
- The default Service type is `LoadBalancer`, so the cloud provider may assign a public IP after deployment.
- The welcome page source file is at `deploy/welcome-page/index.html`.

## Generated Files After Apply

Sensitive access files are written to `terraform_script/generated/` with restrictive permissions:

- `<project>-<environment>-bastion-keypair.pem`
- `<project>-<environment>-worker-keypair.pem`
- `<VPN certificate ID>.ovpn`
- `devops_k8s_config`

The kubeconfig is private and is valid for two hours.

If FileNAS is enabled, `terraform output` plus the BytePlus console or CLI can
be used to confirm the live file systems and mount targets after apply.

## Step-By-Step Access After Deployment

## Step 10: Connect To The VPN

Import the generated `.ovpn` file into your OpenVPN client and connect.

By default:

- SSH to the bastion is allowed only from the VPN client pool `192.168.10.0/24`
- the VKE API is private

If the VPN is not connected, bastion SSH and cluster access will usually fail.

## Step 11: SSH To The Bastion

The example below assumes the default project and environment naming remains unchanged:

```bash
bastion_ip="$(./terraform.sh output -raw bastion-private-ip)"
ssh -i terraform_script/generated/app_project-uat-bastion-keypair.pem "devops@$bastion_ip"
```

If you changed project or environment naming, adjust the PEM filename
accordingly. Generated filenames follow the sanitized deployment prefix, so a
project name containing underscores will appear with hyphens there.

## Step 12: Copy The Kubeconfig To The Bastion

```bash
scp -i terraform_script/generated/app_project-uat-bastion-keypair.pem \
  terraform_script/generated/devops_k8s_config "devops@$bastion_ip:/home/devops/.kube/config"
```

## Step 13: Verify Cluster Readiness On The Bastion

After SSH login, run:

```bash
kubectl get nodes
kubectl get pods -A
```

Expected result:

- nodes are in `Ready` state
- core system Pods are running

## Step 14: Renew The Kubeconfig If It Expires

The generated kubeconfig expires after two hours. To regenerate it:

```bash
./terraform.sh apply -replace=bytepluscc_vke_kubeconfig.devops_k8s_config
```

Then copy the refreshed `terraform_script/generated/devops_k8s_config` to the bastion again.

## Optional: Save A Plan And Apply That Exact Plan Later

If you want to review and then apply an exact saved plan:

```bash
mkdir -p terraform_script/generated
./terraform.sh plan -out=generated/terraform.tfplan
terraform -chdir=terraform_script apply generated/terraform.tfplan
```

When applying a saved plan, do not add `-var-file`.

If you rely on `nas_permission_group_name`, prefer `./terraform.sh plan` and
`./terraform.sh apply` rather than a native saved-plan workflow, because the
wrapper performs the BytePlus CLI lookup before invoking Terraform.

## Step-By-Step Destroy

## Step 15: Review The Destroy Plan

```bash
./terraform.sh plan -destroy
```

Confirm that the resources listed for deletion match what you expect.

## Step 16: Destroy The Environment

```bash
./terraform.sh destroy
```

For already-authorized unattended execution:

```bash
./terraform.sh destroy -auto-approve
```

Destroy removes:

- the Terraform-managed project
- all Terraform-managed infrastructure
- generated access files owned by this state

Preserve any needed data, evidence, or connection material before destroy. The project has no deletion protection.

## Rebuild After Destroy

If you destroy the environment and later run `apply` again, the Terraform-managed
infrastructure is expected to come back, but the rebuilt environment should be
treated as a new environment rather than as an in-place resume of the old one.

What `./terraform.sh apply` is expected to recreate:

- the BytePlus IAM project
- the VPC, subnets, NAT gateway, SNAT, and related network resources
- the private VKE cluster
- the VKE node pool defined in Terraform
- the bastion host
- the VPN resources
- FileNAS resources if `enable_filenas = true`
- generated access artifacts under `terraform_script/generated/`

What does not automatically come back just from Terraform:

- the sample welcome web server Deployment, Service, and ConfigMap
- any Kubernetes workloads or custom resources created after cluster creation
- any in-cluster data stored in Kubernetes volumes unless you back it up separately

Important practical consequences:

- resource IDs may change after the rebuild
- public IP addresses may change
- the bastion IP may change
- the sample web server `LoadBalancer` IP will likely change
- kubeconfig, PEM files, and VPN artifacts will be regenerated
- any previous Kubernetes workload data should be assumed lost unless you back it up and restore it

## Rebuild The Welcome Web Server After Destroy

The sample welcome web server is not created by Terraform. After a fresh
`destroy` plus `apply`, it must be deployed again as a post-provisioning step.

Recommended rebuild sequence:

1. Recreate the infrastructure:

```bash
./terraform.sh apply
```

2. Refresh the kubeconfig if needed:

```bash
./terraform.sh apply -replace=bytepluscc_vke_kubeconfig.devops_k8s_config
```

3. SSH to the bastion and copy the refreshed kubeconfig to `/home/devops/.kube/config` if needed.
4. Ensure `kubectl` is installed on the bastion or the VPN-connected local shell.
5. Deploy the welcome app again:

```bash
./scripts/deploy_welcome_app.sh check
./scripts/deploy_welcome_app.sh deploy
./scripts/deploy_welcome_app.sh status
```

6. Verify the rebuilt deployment:

```bash
kubectl -n default get deployment,service,pods -l app=byteplus-welcome
```

7. Test an external HTTP request against the new web server `LoadBalancer` IP.

## How Destroy Works

Use `terraform.sh destroy` instead of native `terraform destroy`.

Reason:

- VKE does not allow independent deletion of required CoreDNS and metrics-server add-ons.
- `scripts/destroy.py` reviews the destroy plan first.
- If the cluster is also being deleted, the helper removes only the two required add-on records from state and lets VKE delete them with the cluster.
- The helper stores private teardown records under `.terraform-teardown/`.

If a destroy partially fails, keep `.terraform-teardown/`, resolve the issue, and rerun the same destroy command.

## Known Limitations And Special Notes

- Most resources use `bytepluscc 0.0.61`.
- The bastion alone uses `byteplus 0.0.25` as a compatibility workaround for repeated ECS drift seen with `bytepluscc`.
- Switching the bastion back to `bytepluscc` requires new validation and may require state migration.
- Bastion `user_data` does not update in place after creation.
- If you change `terraform_script/20-bastion-cloudinit.yml`, replace the bastion explicitly:

```bash
./terraform.sh apply -replace=byteplus_ecs_instance.ecs_bastion
```

This replacement can also replace the bastion EIP, so the public IP may change.
- FileNAS is modeled as zonal file systems with same-AZ mount targets only. Cross-zone mount-target attempts were rejected during validation and are intentionally not represented in Terraform.
- The sample welcome web server is not part of Terraform. It is a post-provisioning Kubernetes step that requires private-cluster connectivity.

## Validation Status

This improved version was validated in a separate validation account on 2026-10-29 with:

- successful deployment
- a follow-up `No changes` plan
- a repeated apply with zero changes
- complete teardown
- successful FileNAS creation with stable same-AZ mount targets

During validation:

- cluster nodes became ready
- system Pods became ready
- a temporary workload completed image pull, DNS, and outbound HTTP checks through NAT
- bastion cloud-init completed successfully
- VPN certificate and TLS negotiation were verified
- FileNAS instances and supported mount targets became available

The sample welcome web server included in this standalone repo is intentionally
simple and should be treated as a starter workload rather than a separately
validated production component.

Not yet validated in your account:

- your account permissions
- your quotas
- your image availability
- your exact end-to-end VPN routing
- your VPN-to-SSH path

You must validate those in your own environment after deployment.

## Native Terraform Equivalents

If you need to bypass the wrapper for specific cases, the equivalent native commands are:

```bash
terraform -chdir=terraform_script init -lockfile=readonly
terraform -chdir=terraform_script plan -var-file=var.tfvars
terraform -chdir=terraform_script apply -var-file=var.tfvars
```

For normal operator workflow, prefer `./terraform.sh`.

For FileNAS with `nas_permission_group_name`, prefer the wrapper exclusively,
because native Terraform commands do not perform the `bp` permission-group lookup.
