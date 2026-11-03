resource "bytepluscc_vpn_ssl_vpn_server" "vpn_server" {
  compress            = false
  client_ip_pool      = "192.168.10.0/24"
  project_name        = bytepluscc_iam_project.app_project.project_name
  port                = 1194
  ssl_vpn_server_name = "${local.resource_prefix}-vpn-server"
  local_subnets = [
    bytepluscc_vpc_subnet.public_subnet_1a.cidr_block
  ]
  vpn_gateway_id             = bytepluscc_vpn_vpn_gateway.vpn_gateway.id
  auth                       = "SHA1"
  cipher                     = "AES-128-CBC"
  client_cert_session_policy = "PreemptExisting" # no Reuse cert
  protocol                   = "TCP"


  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-vpn-server"
    },
    {
      key   = "ZONE"
      value = "public"
    }
  ])
}
