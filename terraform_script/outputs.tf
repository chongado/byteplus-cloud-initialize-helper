output "project_name" {
  value = bytepluscc_iam_project.app_project.project_name
}

output "region" {
  value = var.region
}

output "vpc_id" {
  value = bytepluscc_vpc_vpc.vpc.id
}

output "cluster_id" {
  value = bytepluscc_vke_cluster.vke_cluster.id
}

output "bastion_instance_id" {
  value = byteplus_ecs_instance.ecs_bastion.id
}

output "generated_directory" {
  value = abspath("${path.module}/generated")
}
