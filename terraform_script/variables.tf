variable "region" {
  default     = "ap-southeast-1"
  description = "BytePlus region: Johor"
}

variable "project_name" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Production, UAT, QA, Develop"
}

variable "vke_version" {
  default = "1.36"
}

variable "byteplus_access_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Optional. Prefer BYTEPLUS_ACCESS_KEY in the environment."
}

variable "byteplus_secret_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Optional. Prefer BYTEPLUS_SECRET_KEY in the environment."
}

variable "enable_filenas" {
  type        = bool
  default     = false
  description = "Set true to create the FileNAS file systems in this stack."
}

variable "nas_permission_group_id" {
  type        = string
  default     = ""
  description = "Optional FileNAS permission group ID. When empty, mount points are skipped."
}

variable "nas_permission_group_name" {
  type        = string
  default     = ""
  description = "Optional FileNAS permission group name. terraform.sh can resolve this to nas_permission_group_id through the bp CLI."
}

variable "bastion_image_id" {
  type        = string
  description = "Ubuntu 24.04 image ID for the bastion host (find in BytePlus console > ECS > Images > Public Images)"
  default     = "image-yde3i2v6bwbhccnzezc6"
}

variable "node_image_id" {
  type        = string
  description = "veLinux 2.0 64 bit"
  default     = "image-yd7m36o070bhccsa6p6o"
}

locals {
  # Cloud resource names reject some characters such as underscores, so keep
  # the actual IAM project name and derive a deployable name prefix separately.
  resource_name_project = trim(replace(var.project_name, "/[^0-9A-Za-z-]+/", "-"), "-")
  resource_prefix       = "${local.resource_name_project}-${var.environment}"
}

locals {
  vpc_cidr = "10.0.0.0/16"
}

locals {
  public_subnet_1a  = "10.0.65.0/24"
  public_subnet_1b  = "10.0.66.0/24"
  public_subnet_1c  = "10.0.67.0/24"
  private_subnet_1a = "10.0.144.0/20"
  private_subnet_1b = "10.0.160.0/20"
  private_subnet_1c = "10.0.176.0/20"
}

locals {
  zone_az_a = "${var.region}a"
  zone_az_b = "${var.region}b"
  zone_az_c = "${var.region}c"
}

variable "project_id" {
  type    = string
  default = ""
}

# locals {
#   default_byteplus_tags = {
#     ENVIRONMENT  = "${var.environment}"
#     PROJECT_NAME = "${var.project_name}"
#     PROJECT_ID   = "${var.project_id}"
#   }
# }
locals {
  default_byteplus_tags = [
    {
      key   = "ENVIRONMENT"
      value = "${var.environment}"
    },
    { key   = "PROJECT_NAME"
      value = "${var.project_name}"
    },
    { key   = "PROJECT_ID"
      value = "${var.project_id}"
    }
  ]
}
