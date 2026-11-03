terraform {
  # Single-operator CLI deployment. Keep state and backups out of Git.
  # Configure and migrate to a shared backend before using concurrent operators.
  backend "local" {
    path = "terraform.tfstate"
  }
}
