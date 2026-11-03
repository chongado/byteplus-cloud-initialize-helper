resource "bytepluscc_vpn_vpn_gateway" "vpn_gateway" {
  bandwidth           = 5
  billing_type        = 2
  dual_tunnel_enabled = false
  ip_stack_type       = "ipv4_only"
  ip_version          = "ipv4"
  vpn_gateway_name    = "${local.resource_prefix}-vpn-gateway"
  ipsec_enabled       = false
  ssl_enabled         = true
  ssl_max_connections = 5
  project_name        = bytepluscc_iam_project.app_project.project_name
  vpc_id              = bytepluscc_vpc_vpc.vpc.id
  subnet_id           = bytepluscc_vpc_subnet.public_subnet_1a.id

  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-vpn-gateway"
    },
    {
      key   = "ZONE"
      value = "public"
    }
  ])

  depends_on = [
    time_sleep.wait_after_security_groups,
  ]
}

output "vpn_public_ip" {
  value = bytepluscc_vpn_vpn_gateway.vpn_gateway.ip_address
}
