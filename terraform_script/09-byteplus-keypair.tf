resource "tls_private_key" "bastion_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "bytepluscc_ecs_keypair" "bastion_keypair" {
  project_name  = bytepluscc_iam_project.app_project.project_name
  key_pair_name = "${local.resource_prefix}-bastion-keypair"
  public_key    = tls_private_key.bastion_private_key.public_key_openssh

}

locals {
  bastion_key_export_path  = path.cwd
  bastion_key_name         = bytepluscc_ecs_keypair.bastion_keypair.key_pair_name
  bastion_public_key_value = bytepluscc_ecs_keypair.bastion_keypair.public_key
}

resource "tls_private_key" "worker_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "bytepluscc_ecs_keypair" "worker_keypair" {
  project_name  = bytepluscc_iam_project.app_project.project_name
  key_pair_name = "${local.resource_prefix}-worker-keypair"
  public_key    = tls_private_key.worker_private_key.public_key_openssh

}

locals {
  worker_key_export_path  = path.cwd
  worker_key_name         = bytepluscc_ecs_keypair.worker_keypair.key_pair_name
  worker_public_key_value = bytepluscc_ecs_keypair.worker_keypair.public_key
}

output "worker_public_key_value" {
  value = local.worker_public_key_value
}

resource "local_sensitive_file" "bastion_private_key" {
  filename             = "${path.module}/generated/${bytepluscc_ecs_keypair.bastion_keypair.key_pair_name}.pem"
  content              = tls_private_key.bastion_private_key.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_sensitive_file" "worker_private_key" {
  filename             = "${path.module}/generated/${bytepluscc_ecs_keypair.worker_keypair.key_pair_name}.pem"
  content              = tls_private_key.worker_private_key.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}
