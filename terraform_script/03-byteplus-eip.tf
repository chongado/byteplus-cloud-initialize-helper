resource "bytepluscc_vpc_eip" "bastion" {
  name          = "${local.resource_prefix}-bastion-eip"
  bandwidth     = 10
  billing_type  = 3
  isp           = "BGP"
  instance_id   = byteplus_ecs_instance.ecs_bastion.id
  instance_type = "EcsInstance"
  project_name  = bytepluscc_iam_project.app_project.project_name

  lifecycle {
    # bytepluscc 0.0.61 cannot reliably update the ECS association in place.
    # A future bastion replacement therefore reallocates its EIP as well.
    replace_triggered_by = [byteplus_ecs_instance.ecs_bastion.id]
  }

  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-bastion-eip"
    }
  ])
}

resource "bytepluscc_vpc_eip" "natgw" {
  name          = "${local.resource_prefix}-natgw-eip"
  bandwidth     = 100
  billing_type  = 3
  isp           = "BGP"
  instance_id   = bytepluscc_natgateway_ngw.natgw.id
  instance_type = "Nat"
  project_name  = bytepluscc_iam_project.app_project.project_name

  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-natgw-eip"
    }
  ])
}
