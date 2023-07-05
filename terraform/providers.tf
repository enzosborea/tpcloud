terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.51.1"
    }
  }
}

provider "openstack" {
  user_name   = "admin"
  password    = "tpcloud"
  auth_url    = "http://10.0.20.16/identity"
  tenant_name = "admin"
  region      = var.region_name
}
