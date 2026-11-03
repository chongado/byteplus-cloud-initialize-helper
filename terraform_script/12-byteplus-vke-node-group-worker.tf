# resource "bytepluscc_vke_node_pool" "worker_ng" {
#   cluster_id = bytepluscc_vke_cluster.vke_cluster.id
#   name       = "${local.resource_prefix}-worker-ng"

#   auto_scaling = {
#     enabled          = false
#     min_replicas     = 0
#     max_replicas     = 4
#     desired_replicas = 3
#     priority         = 5
#     subnet_policy    = "ZoneBalance"
#   }

#   node_config = {
#     instance_type_ids    = ["ecs.g1.large"]
#     instance_charge_type = "PostPaid"
#     name_prefix          = "${local.resource_prefix}-worker"
#     image_id             = var.node_image_id

#     subnet_ids = [
#       bytepluscc_vpc_subnet.private_subnet_1.id,
#       bytepluscc_vpc_subnet.private_subnet_2.id,
#       bytepluscc_vpc_subnet.private_subnet_3.id,
#     ]

#     system_volume = {
#       type = "ESSD_PL0"
#       size = 50
#     }

#     security = {
#       security_group_ids = [bytepluscc_vpc_security_group.worker_sg.id]
#       login = {
#         ssh_key_pair_name = bytepluscc_ecs_keypair.worker_keypair.key_pair_name
#       }
#     }
#   }

#   kubernetes_config = {
#     cordon = false
#     labels = [
#       {
#         key   = "role"
#         value = "worker"
#       },
#       {
#         key   = "env"
#         value = var.environment
#       }
#     ]
#   }
# }
