resource "bytepluscc_vpc_prefix_list" "pl_pub" {
  prefix_list_name = "${local.resource_prefix}-pubsub-pl"
  max_entries      = 3
  ip_version       = "IPv4"
  project_name     = bytepluscc_iam_project.app_project.project_name
  prefix_list_entries = [
    {
      cidr        = local.public_subnet_1a
      description = "public-subnet-1a"
    },
    {
      cidr        = local.public_subnet_1b
      description = "public-subnet-1b"
    },
    {
      cidr        = local.public_subnet_1c
      description = "public-subnet-1c"
    }
  ]

  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-pubsub-pl"
    },
    {
      key   = "ZONE"
      value = "public"
    }
  ])

  depends_on = [
    bytepluscc_vpc_subnet.public_subnet_1a,
    bytepluscc_vpc_subnet.public_subnet_1b,
    bytepluscc_vpc_subnet.public_subnet_1c,
  ]
}

resource "bytepluscc_vpc_prefix_list" "pl_pri" {
  prefix_list_name = "${local.resource_prefix}-prisub-pl"
  max_entries      = 3
  ip_version       = "IPv4"
  project_name     = bytepluscc_iam_project.app_project.project_name
  prefix_list_entries = [
    {
      cidr        = local.private_subnet_1a
      description = "private-subnet-1a"
    },
    {
      cidr        = local.private_subnet_1b
      description = "private-subnet-1b"
    },
    {
      cidr        = local.private_subnet_1c
      description = "private-subnet-1c"
    }
  ]
  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-prisub-pl"
    },
    {
      key   = "ZONE"
      value = "private"
    }
  ])


  depends_on = [
    bytepluscc_vpc_subnet.private_subnet_1a,
    bytepluscc_vpc_subnet.private_subnet_1b,
    bytepluscc_vpc_subnet.private_subnet_1c,
  ]
}
