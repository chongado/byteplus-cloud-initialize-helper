# resource "bytepluscc_iam_user" "k8s_bastion_user" {
#   user_name    = "${local.resource_prefix}-vke-admin"
#   display_name = "${local.resource_prefix}-vke-admin"
#   description  = "VKE admin user for kubectl on bastion"
# }

# resource "bytepluscc_iam_policy" "k8s_bastion" {
#   policy_name = "${local.resource_prefix}-k8s-bastion-policy"
#   policy_type = "Custom"
#   description = "Kubectl Executor on Bastion"
#   policy_document = jsonencode({
#     Statement = [
#       {
#         Sid      = "vkeAdmin"
#         Effect   = "Allow"
#         Action   = ["vke:*"]
#         Resource = ["*"]
#       }
#     ]
#   })

#   policy_users = [
#     {
#       name = bytepluscc_iam_user.k8s_bastion_user.user_name
#     }
#   ]

#   depends_on = [bytepluscc_vke_cluster.vke_cluster]
# }

# resource "bytepluscc_iam_accesskey" "k8s_bastion_user_cred" {
#   user_name = bytepluscc_iam_user.k8s_bastion_user.user_name
# }

# locals {
#   vke_access_key = bytepluscc_iam_accesskey.k8s_bastion_user_cred.access_key_id
#   vke_secret_key = bytepluscc_iam_accesskey.k8s_bastion_user_cred.secret_access_key
# }

# output "ak_k8s_bastion_user" {
#   value = bytepluscc_iam_accesskey.k8s_bastion_user_cred.access_key_id
# }

# output "sk_k8s_bastion_user" {
#   value     = bytepluscc_iam_accesskey.k8s_bastion_user_cred.secret_access_key
#   sensitive = true
# }
