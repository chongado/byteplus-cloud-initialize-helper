resource "bytepluscc_natgateway_ngw" "natgw" {
  nat_gateway_name = "${local.resource_prefix}-public-natgw"
  vpc_id           = bytepluscc_vpc_vpc.vpc.id
  subnet_id        = bytepluscc_vpc_subnet.private_subnet_1a.id
  network_type     = "internet"
  spec             = "Small"
  billing_type     = 2
  project_name     = bytepluscc_iam_project.app_project.project_name

  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-natgw"
    }
  ])

  depends_on = [
    time_sleep.wait_after_security_groups,
  ]
}

resource "bytepluscc_natgateway_snatentry" "natgw_snat_entry_priv_1a" {
  snat_entry_name = "${local.resource_prefix}-private-1a"
  nat_gateway_id  = bytepluscc_natgateway_ngw.natgw.id
  eip_id          = bytepluscc_vpc_eip.natgw.id
  subnet_id       = bytepluscc_vpc_subnet.private_subnet_1a.id
}

resource "bytepluscc_natgateway_snatentry" "natgw_snat_entry_priv_1b" {
  snat_entry_name = "${local.resource_prefix}-private-1b"
  nat_gateway_id  = bytepluscc_natgateway_ngw.natgw.id
  eip_id          = bytepluscc_vpc_eip.natgw.id
  subnet_id       = bytepluscc_vpc_subnet.private_subnet_1b.id
}

resource "bytepluscc_natgateway_snatentry" "natgw_snat_entry_priv_1c" {
  snat_entry_name = "${local.resource_prefix}-private-1c"
  nat_gateway_id  = bytepluscc_natgateway_ngw.natgw.id
  eip_id          = bytepluscc_vpc_eip.natgw.id
  subnet_id       = bytepluscc_vpc_subnet.private_subnet_1c.id
}

# resource "bytepluscc_natgateway_snatentry" "private_subnet_1" {
#   snat_entry_name = "${local.resource_prefix}-snat-pri1"
#   nat_gateway_id  = bytepluscc_natgateway_ngw.natgw.id
#   eip_id          = bytepluscc_vpc_eip.natgw.id
#   source_cidr     = local.private_subnet_1

#   depends_on = [bytepluscc_vpc_eip.natgw]
# }

# resource "bytepluscc_natgateway_snatentry" "private_subnet_2" {
#   snat_entry_name = "${local.resource_prefix}-snat-pri2"
#   nat_gateway_id  = bytepluscc_natgateway_ngw.natgw.id
#   eip_id          = bytepluscc_vpc_eip.natgw.id
#   source_cidr     = local.private_subnet_2

#   depends_on = [bytepluscc_vpc_eip.natgw]
# }

# resource "bytepluscc_natgateway_snatentry" "private_subnet_3" {
#   snat_entry_name = "${local.resource_prefix}-snat-pri3"
#   nat_gateway_id  = bytepluscc_natgateway_ngw.natgw.id
#   eip_id          = bytepluscc_vpc_eip.natgw.id
#   source_cidr     = local.private_subnet_3

#   depends_on = [bytepluscc_vpc_eip.natgw]
# }
