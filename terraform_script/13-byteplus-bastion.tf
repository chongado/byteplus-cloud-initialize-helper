locals {
  bastion_node_type = "ecs.e-c1m2.large"
}

# Native provider for ECS only: bytepluscc 0.0.61 emits perpetual unknown
# values for omitted image/NIC/disk metadata, even with ignore_changes.
resource "byteplus_ecs_instance" "ecs_bastion" {
  instance_name        = "${local.resource_prefix}-bastion"
  host_name            = "${local.resource_prefix}-bastion"
  instance_type        = local.bastion_node_type
  zone_id              = local.zone_az_a
  instance_charge_type = "PostPaid"
  project_name         = bytepluscc_iam_project.app_project.project_name
  image_id             = var.bastion_image_id
  subnet_id            = bytepluscc_vpc_subnet.public_subnet_1a.id
  security_group_ids   = [bytepluscc_vpc_security_group.bastion_sg.id]
  key_pair_name        = bytepluscc_ecs_keypair.bastion_keypair.key_pair_name
  system_volume_size   = 50
  system_volume_type   = "ESSD_PL0"

  lifecycle {
    # Native provider import does not populate these create-only/default inputs.
    # cloud-init is intentionally immutable; apply template changes via -replace.
    ignore_changes = [user_data, security_enhancement_strategy, hpc_cluster_id, spot_price_limit]
  }

  user_data = base64encode(templatefile("${path.module}/20-bastion-cloudinit.yml", {
    region            = var.region
    ssh_key_generated = tls_private_key.bastion_private_key.public_key_openssh
  }))

  dynamic "tags" {
    for_each = concat(local.default_byteplus_tags, [
      { key = "RESOURCE_NAME", value = "${local.resource_prefix}-bastion" },
      { key = "ZONE", value = "public" },
    ])
    content {
      key   = tags.value.key
      value = tags.value.value
    }
  }
}

output "bastion-eip-ip" {
  value = bytepluscc_vpc_eip.bastion.eip_address
}
output "bastion-private-ip" {
  value = byteplus_ecs_instance.ecs_bastion.primary_ip_address
}
