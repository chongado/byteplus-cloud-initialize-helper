resource "bytepluscc_vke_node_pool" "control_ng" {
  cluster_id = bytepluscc_vke_cluster.vke_cluster.id
  name       = "${local.resource_prefix}-control-ng"

  # management = {
  #   enabled = true
  # }

  auto_scaling = {
    enabled          = false
    min_replicas     = 0
    max_replicas     = 2
    desired_replicas = 2
    priority         = 5
    subnet_policy    = "ZoneBalance"
  }

  node_config = {
    instance_type_ids     = ["ecs.e-c1m4.xlarge"]
    instance_charge_type  = "PostPaid"
    name_prefix           = "${local.resource_prefix}-control"
    image_id              = var.node_image_id
    project_name          = bytepluscc_iam_project.app_project.project_name
    public_access_enabled = false
    subnet_ids = [
      bytepluscc_vpc_subnet.private_subnet_1a.id,
    ]

    system_volume = {
      type = "ESSD_PL0"
      size = 50
    }

    security = {
      security_group_ids = concat(
        [bytepluscc_vpc_security_group.worker_sg.id],
        tolist(bytepluscc_vke_cluster.vke_cluster.cluster_config.security_group_ids),
      )
      login = {
        ssh_key_pair_name = bytepluscc_ecs_keypair.worker_keypair.key_pair_name
      }
    }
  }

  kubernetes_config = {
    name_prefix        = "control"
    name_use_hostname  = false
    auto_sync_disabled = false
    cordon             = false
    kubelet_config = {
      max_pods = 110
    }
    labels = [
      {
        key   = "role"
        value = "control"
      }
    ]
  }
}
