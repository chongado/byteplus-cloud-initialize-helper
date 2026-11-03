resource "bytepluscc_vpc_security_group" "worker_sg" {
  security_group_name = "${local.resource_prefix}-worker-sg"
  description         = "Allow worker nodes traffic"
  vpc_id              = bytepluscc_vpc_vpc.vpc.id
  project_name        = bytepluscc_iam_project.app_project.project_name

  ingress_permissions = [
    {
      description     = "Allow all traffic between nodes - prefix list private subnet"
      policy          = "accept"
      protocol        = "all"
      port_start      = -1
      port_end        = -1
      priority        = 1
      cidr_ip         = ""
      prefix_list_id  = bytepluscc_vpc_prefix_list.pl_pri.id
      source_group_id = ""
    },
    # {
    #   description     = "Allow all traffic between nodes - private subnet 1b"
    #   policy          = "accept"
    #   protocol        = "all"
    #   port_start      = -1
    #   port_end        = -1
    #   priority        = 2
    #   cidr_ip         = local.private_subnet_1b
    #   prefix_list_id  = ""
    #   source_group_id = ""
    # },
    # {
    #   description     = "Allow all traffic between nodes - private subnet 1c"
    #   policy          = "accept"
    #   protocol        = "all"
    #   port_start      = -1
    #   port_end        = -1
    #   priority        = 3
    #   cidr_ip         = local.private_subnet_1c
    #   prefix_list_id  = ""
    #   source_group_id = ""
    # },
    {
      description     = "NFS"
      policy          = "accept"
      protocol        = "tcp"
      port_start      = 2049
      port_end        = 2049
      priority        = 6
      cidr_ip         = local.vpc_cidr
      prefix_list_id  = ""
      source_group_id = ""
    }
  ]

  #   egress_permissions = [
  #     {
  #       description     = "Allows all egress"
  #       policy          = "accept"
  #       protocol        = "all"
  #       port_start      = -1
  #       port_end        = -1
  #       priority        = 100
  #       cidr_ip         = "0.0.0.0/0"
  #       prefix_list_id  = ""
  #       source_group_id = ""
  #     }
  #   ]
  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-worker-sg"
    },
    {
      key   = "ZONE"
      value = "worker"
    }
  ])

  depends_on = [
    time_sleep.wait_after_subnets,
  ]
}

# Bastion Security Group
resource "bytepluscc_vpc_security_group" "bastion_sg" {
  depends_on          = [time_sleep.wait_after_subnets]
  security_group_name = "${local.resource_prefix}-bastion-sg"
  description         = "bastion-sg"
  vpc_id              = bytepluscc_vpc_vpc.vpc.id
  project_name        = bytepluscc_iam_project.app_project.project_name

  ingress_permissions = [
    {
      description     = "Allow SSH from vpn"
      policy          = "accept"
      protocol        = "tcp"
      port_start      = 22
      port_end        = 22
      priority        = 1
      cidr_ip         = "192.168.10.0/24"
      prefix_list_id  = ""
      source_group_id = ""
    },
    {
      description     = "Allow PING from vpn"
      policy          = "accept"
      protocol        = "icmp"
      port_start      = "-1"
      port_end        = "-1"
      priority        = 1
      cidr_ip         = "192.168.10.0/24"
      prefix_list_id  = ""
      source_group_id = ""
    },
  ]


  #   egress_permissions = [
  #     {
  #       description     = "Allows all access"
  #       policy          = "accept"
  #       protocol        = "all"
  #       port_start      = -1
  #       port_end        = -1
  #       priority        = 100
  #       cidr_ip         = "0.0.0.0/0"
  #       prefix_list_id  = ""
  #       source_group_id = ""
  #     }
  #   ]

  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-bastion-sg"
    },
    {
      key   = "ZONE"
      value = "public"
    }
  ])
}

# BytePlus can leave a VPC in a transient state for a short period after subnet
# creation. Let both security groups finish before starting heavier VPC
# consumers such as NAT/VPN/VKE to reduce InvalidVpc.InvalidStatus retries.
resource "time_sleep" "wait_after_security_groups" {
  create_duration = "45s"

  depends_on = [
    bytepluscc_vpc_security_group.worker_sg,
    bytepluscc_vpc_security_group.bastion_sg,
  ]
}

# # VKE API Security Group
# # Note: BytePlus VKE manages its control-plane security internally and does not
# # accept externally-attached security groups on the API server. This SG is created
# # for parity and can be used with additional network policies if required.
# resource "bytepluscc_vpc_security_group" "vke_api_sg" {
#   security_group_name = "${local.resource_prefix}-vke-api-sg"
#   description         = "vke-api-sg"
#   vpc_id              = bytepluscc_vpc_vpc.vpc.id

#   ingress_permissions = [
#     {
#       description     = "Allow kubectl from bastion"
#       policy          = "accept"
#       protocol        = "tcp"
#       port_start      = 443
#       port_end        = 443
#       priority        = 1
#       cidr_ip         = "${bytepluscc_ecs_instance.ec2_bastion.primary_network_interface.primary_ip_address}/32"
#       prefix_list_id  = ""
#       source_group_id = ""
#     }
#   ]

#   egress_permissions = [
#     {
#       description     = "Allows all access"
#       policy          = "accept"
#       protocol        = "all"
#       port_start      = -1
#       port_end        = -1
#       priority        = 100
#       cidr_ip         = "0.0.0.0/0"
#       prefix_list_id  = ""
#       source_group_id = ""
#     }
#   ]

#   tags = [
#     {
#       key  = "RESOURCE_NAME"
#       value = "${local.resource_prefix}-vke-api-sg"
#     },
#     {
#       key   = "ZONE"
#       value = "public"
#     }
#   ]

#   depends_on = [bytepluscc_ecs_instance.ec2_bastion]
# }
