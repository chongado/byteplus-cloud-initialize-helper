resource "bytepluscc_iam_project" "app_project" {
  project_name = var.project_name
  display_name = var.project_name
  description  = "${var.project_name} infrastructure managed by Terraform"
}
