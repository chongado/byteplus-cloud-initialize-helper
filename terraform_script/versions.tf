
terraform {
  required_providers {
    # Temporary ECS-only workaround for perpetual nested computed diffs in
    # bytepluscc 0.0.61. All other cloud resources continue to use bytepluscc.
    byteplus = {
      source  = "byteplus-sdk/byteplus"
      version = "= 0.0.25"
    }
    bytepluscc = {
      source  = "byteplus-sdk/bytepluscc"
      version = "~> 0.0.61"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14.1"
    }
  }

  required_version = ">= v1.9.8"
}
