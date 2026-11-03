# resource "bytepluscc_vke_node_pool" "db_ng" {
#   cluster_id = bytepluscc_vke_cluster.vke_cluster.id
#   name       = "${local.resource_prefix}-db-ng-2"

#   auto_scaling = {
#     enabled          = false
#     min_replicas     = 0
#     max_replicas     = 4
#     desired_replicas = 4
#     priority         = 5
#     subnet_policy    = "ZoneBalance"
#   }

#   node_config = {
#     instance_type_ids    = ["ecs.g1.large"]
#     instance_charge_type = "PostPaid"
#     name_prefix          = "${local.resource_prefix}-db"
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
#         value = "db"
#       },
#       {
#         key   = "env"
#         value = var.environment
#       }
#     ]
#   }
# }
