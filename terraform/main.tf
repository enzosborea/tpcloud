resource "openstack_images_image_v2" "ubuntu" {
  name             = "ubuntu"
  image_source_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  container_format = "bare"
  disk_format      = "qcow2"
}

resource "openstack_compute_instance_v2" "server" {
  name            = "ubuntu-server"
  image_name      = "ubuntu"
  flavor_name     = "m1.small"
  security_groups = ["default"]

  network {
    name = var.external_network
  }
}

resource "openstack_networking_network_v2" "external" {
  name           = var.external_network
  admin_state_up = "true"
  external       = "true"
  segments {
    network_type = "local"
  }
}

resource "openstack_networking_subnet_v2" "external-subnet" {
  name            = "external-subnet"
  network_id      = openstack_networking_network_v2.external.id
  cidr            = "20.0.0.0/8"
  gateway_ip      = "20.0.0.1"
  dns_nameservers = ["20.0.0.254", "20.0.0.253"]
  allocation_pool {
    start = "20.0.0.2"
    end   = "20.0.254.254"
  }
}

resource "openstack_networking_router_v2" "external-router" {
  name                = "external-router"
  admin_state_up      = true
  external_network_id = openstack_networking_network_v2.external.id
}


resource "openstack_networking_floatingip_v2" "fip_1" {
  pool = var.external_network
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = openstack_networking_floatingip_v2.fip_1.address
  instance_id = openstack_compute_instance_v2.server.id
}