resource "bytepluscc_vpc_vpc" "vpc" {
  vpc_name   = "${local.resource_prefix}-vpc"
  cidr_block = local.vpc_cidr
  # support_ipv_4_gateway = true
  project_name = bytepluscc_iam_project.app_project.project_name
  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-vpc"
    }
  ])
}
resource "time_sleep" "vpc_ready" {
  depends_on      = [bytepluscc_vpc_vpc.vpc]
  create_duration = "30s"
}

# output "byteplus_projecs" {
#   value = resource.bytepluscc_vpc_vpc.vpc
# }
