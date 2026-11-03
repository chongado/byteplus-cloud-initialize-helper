resource "bytepluscc_vpn_ssl_vpn_client_cert" "vpn_client_cert" {
  ssl_vpn_server_id        = bytepluscc_vpn_ssl_vpn_server.vpn_server.id
  ssl_vpn_client_cert_name = "${local.resource_prefix}-vpn-client-cert-1"



  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-vpn-client-cert-1"
    }
  ])
}


# resource "null_resource" "create_ovpn_cert_config" {
#   provisioner "local-exec" {
#     command = "echo '${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.open_vpn_client_config}' > ${path.module}/generated/${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.id}.ovpn &&
#      echo '${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.ca_certificate}' >> ${path.module}/generated/${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.id}.ovpn &&
#      echo '${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.client_certificate}' >> ${path.module}/generated/${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.id}.ovpn &&
#      echo '${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.client_key}' >> ${path.module}/generated/${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.id}.ovpn"
#   }

#   depends_on = [bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert]
# }

locals {
  # The API template references separate files. Strip these directives before
  # embedding the certificate and key so the exported profile is self-contained.
  ovpn_inline_base = replace(
    bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.open_vpn_client_config,
    "/(?m)^(ca|cert|key) .*$/",
    "",
  )
}

resource "local_sensitive_file" "ovpn_config" {
  filename             = "${path.module}/generated/${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.id}.ovpn"
  file_permission      = "0600"
  directory_permission = "0700"

  content = <<-EOT
    ${local.ovpn_inline_base}
    <ca>
    ${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.ca_certificate}
    </ca>
    <cert>
    ${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.client_certificate}
    </cert>
    <key>
    ${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.client_key}
    </key>
  EOT
}



# locals {
#   ovpn_base = replace(
#     bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.open_vpn_client_config,
#     "/(?m)^((?:ca|cert|key) .*)$/",
#     "# $1"
#   )
# }

# resource "local_sensitive_file" "ovpn_config" {
#   filename        = "${path.module}/generated/${bytepluscc_vpn_ssl_vpn_client_cert.vpn_client_cert.id}.ovpn"
#   file_permission = "0600"
#   content         = local.ovpn_base
# }
