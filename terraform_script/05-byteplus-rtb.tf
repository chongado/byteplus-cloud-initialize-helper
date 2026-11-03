# resource "bytepluscc_vpc_route_table" "public_rtb" {
#   vpc_id           = bytepluscc_vpc_vpc.vpc.id
#   route_table_name = "${local.resource_prefix}-public-rtb"

#   subnet_ids = [
#     bytepluscc_vpc_subnet.public_subnet_1.id,
#     bytepluscc_vpc_subnet.public_subnet_2.id,
#     bytepluscc_vpc_subnet.public_subnet_3.id,
#   ]

#   tags = [
#     {
#       key  = "RESOURCE_NAME"
#       value = "${local.resource_prefix}-public-rtb"
#     }
#   ]
# }

# resource "bytepluscc_vpc_route_table" "private_rtb" {
#   vpc_id           = bytepluscc_vpc_vpc.vpc.id
#   route_table_name = "${local.resource_prefix}-private-rtb"

#   subnet_ids = [
#     bytepluscc_vpc_subnet.private_subnet_1.id,
#     bytepluscc_vpc_subnet.private_subnet_2.id,
#     bytepluscc_vpc_subnet.private_subnet_3.id,
#   ]

#   custom_route_entries = [
#     {
#       destination_cidr_block = "0.0.0.0/0"
#       next_hop_type          = "NatGW"
#       next_hop_id            = bytepluscc_natgateway_ngw.natgw.id
#       description            = "${local.resource_prefix}-private-nat-route"
#     }
#   ]

#   tags = [
#     {
#       key  = "RESOURCE_NAME"
#       value = "${local.resource_prefix}-private-rtb"
#     }
#   ]
# }
