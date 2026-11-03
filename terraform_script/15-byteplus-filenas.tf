locals {
  filenas_instances = var.enable_filenas ? {
    app = {
      file_system_name = "${local.resource_prefix}-nas"
      zone_id          = local.zone_az_a
      subnet_key       = "1a"
    }
    web = {
      file_system_name = "${local.resource_prefix}-nas-web"
      zone_id          = local.zone_az_b
      subnet_key       = "1b"
    }
  } : {}

  filenas_subnets = {
    "1a" = bytepluscc_vpc_subnet.private_subnet_1a.id
    "1b" = bytepluscc_vpc_subnet.private_subnet_1b.id
    "1c" = bytepluscc_vpc_subnet.private_subnet_1c.id
  }

  # FileNAS file systems are zonal. In practice, BytePlus accepted one mount
  # target per file system in the matching AZ/subnet and rejected the cross-zone
  # combinations. Model only the supported same-AZ targets here.
  filenas_mount_points = var.enable_filenas && var.nas_permission_group_id != "" ? {
    for fs_name, fs in local.filenas_instances :
    "${fs_name}-${fs.subnet_key}" => {
      file_system_key  = fs_name
      mount_point_name = "${local.resource_prefix}-${fs_name}-${fs.subnet_key}"
      subnet_id        = local.filenas_subnets[fs.subnet_key]
    }
  } : {}
}

moved {
  from = bytepluscc_filenas_instance.filenas_app
  to   = bytepluscc_filenas_instance.filenas["app"]
}

resource "bytepluscc_filenas_instance" "filenas" {
  for_each = local.filenas_instances

  file_system_name = each.value.file_system_name
  file_system_type = "Extreme"
  protocol_type    = "NFS"
  charge_type      = "PayAsYouGo"
  zone_id          = each.value.zone_id
  project_name     = var.project_name

  # The provider example uses 105 GiB, and the live resource was created with
  # 105. Repeated attempts to update it down to 100 fail with InvalidRequest.
  capacity = {
    total = 105
  }

  # The upstream provider warns that nested tag sets can create unstable plans
  # unless all nested attributes are fully defined. The live FileNAS state is
  # already read back as null tags, so omit tags here for stable plans.
}

resource "bytepluscc_filenas_mount_point" "filenas" {
  for_each = local.filenas_mount_points

  file_system_id      = bytepluscc_filenas_instance.filenas[each.value.file_system_key].id
  mount_point_name    = each.value.mount_point_name
  permission_group_id = var.nas_permission_group_id
  subnet_id           = each.value.subnet_id
  vpc_id              = bytepluscc_vpc_vpc.vpc.id
}
