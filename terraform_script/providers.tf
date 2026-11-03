
provider "bytepluscc" {
  access_key = var.byteplus_access_key
  secret_key = var.byteplus_secret_key
  region     = var.region
}

provider "byteplus" {
  access_key = var.byteplus_access_key
  secret_key = var.byteplus_secret_key
  region     = var.region
}
