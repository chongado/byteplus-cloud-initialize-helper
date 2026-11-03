resource "bytepluscc_vke_cluster" "vke_cluster" {
  name                      = "${local.resource_prefix}-vke"
  kubernetes_version_create = var.vke_version
  delete_protection_enabled = false
  project_name              = bytepluscc_iam_project.app_project.project_name

  cluster_config = {
    subnet_ids = [
      bytepluscc_vpc_subnet.private_subnet_1a.id,
      bytepluscc_vpc_subnet.private_subnet_1b.id,
      bytepluscc_vpc_subnet.private_subnet_1c.id,
    ]
    api_server_public_access_enabled       = false
    resource_public_access_default_enabled = false
  }

  pods_config = {
    pod_network_mode = "VpcCniShared"
    vpc_cni_config = {
      subnet_ids = [
        bytepluscc_vpc_subnet.private_subnet_1a.id,
        bytepluscc_vpc_subnet.private_subnet_1b.id,
        bytepluscc_vpc_subnet.private_subnet_1c.id,
      ]
    }
  }

  services_config = {
    service_cidrsv_4 = ["172.20.0.0/18"]
  }

  irsa_config = {
    enabled = true
  }
  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-vke"
    }
  ])

  depends_on = [
    time_sleep.wait_after_security_groups,
  ]
}

resource "bytepluscc_vke_addon" "addon_core_dns" {
  cluster_id       = bytepluscc_vke_cluster.vke_cluster.id
  name             = "core-dns"
  deploy_node_type = "Node"
  deploy_mode      = "Unmanaged"
  config = jsonencode({
    Resources = {
      Requests = { Cpu = "100m", Memory = "128Mi" }
      Limits   = { Cpu = "1", Memory = "512Mi" }
    }
  })
}

resource "bytepluscc_vke_addon" "addon_csi_ebs" {
  cluster_id       = bytepluscc_vke_cluster.vke_cluster.id
  name             = "csi-ebs"
  deploy_node_type = "Node"
  deploy_mode      = "Unmanaged"
}

resource "bytepluscc_vke_addon" "addon_snapshot_controller" {
  cluster_id       = bytepluscc_vke_cluster.vke_cluster.id
  name             = "snapshot-controller"
  deploy_node_type = "Node"
  deploy_mode      = "Unmanaged"
}

resource "bytepluscc_vke_addon" "addon_metrics_server" {
  cluster_id       = bytepluscc_vke_cluster.vke_cluster.id
  name             = "metrics-server"
  deploy_node_type = "Node"
  deploy_mode      = "Unmanaged"
}

resource "bytepluscc_vke_addon" "addon_csi_nas" {
  cluster_id       = bytepluscc_vke_cluster.vke_cluster.id
  name             = "csi-nas"
  deploy_node_type = "Node"
  deploy_mode      = "Unmanaged"
}
# resource "bytepluscc_vke_addon" "addon_prometheus_agent" {
#   cluster_id       = bytepluscc_vke_cluster.vke_cluster.id
#   name             = "prometheus-agent"
#   deploy_node_type = "Node"
#   deploy_mode      = "Unmanaged"
# }
resource "bytepluscc_vke_addon" "addon_pod_identity_webhook" {
  cluster_id = bytepluscc_vke_cluster.vke_cluster.id
  name       = "pod-identity-webhook"
  # deploy_node_type = "Node"
  deploy_mode = "Managed"
}

# resource "bytepluscc_vke_addon" "addon_vci_virtual_kubelet" {
#   cluster_id       = bytepluscc_vke_cluster.vke_cluster.id
#   name             = "vci-virtual-kubelet"
#   deploy_node_type = "Node"
#   deploy_mode      = "Unmanaged"
# }


resource "bytepluscc_vke_kubeconfig" "devops_k8s_config" {
  cluster_id     = bytepluscc_vke_cluster.vke_cluster.id
  type           = "Private"
  valid_duration = 2
}

locals {
  devops_k8s_config = base64decode(bytepluscc_vke_kubeconfig.devops_k8s_config.kubeconfig)
}

resource "local_sensitive_file" "devops_k8s_config" {
  filename             = "${path.module}/generated/devops_k8s_config"
  file_permission      = "0600"
  directory_permission = "0700"
  content              = local.devops_k8s_config
}
