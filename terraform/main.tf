resource "openstack_images_image_v2" "ubuntu" {
  name             = "ubuntu-lts"
  image_source_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  container_format = "bare"
  disk_format      = "qcow2"
}

resource "openstack_compute_instance_v2" "server" {
  count           = 2
  name            = "ubuntu-server${count.index}"
  image_id        = openstack_images_image_v2.ubuntu.id
  flavor_name     = "m1.small"
  security_groups = ["default"]

  network {
    name = openstack_networking_network_v2.internal.name
  }
}

resource "openstack_networking_network_v2" "internal" {
  name           = var.internal_network
  admin_state_up = "true"
  external       = "false"
}

resource "openstack_networking_subnet_v2" "internal-subnet" {
  name       = "internal-subnet"
  network_id = openstack_networking_network_v2.internal.id
  cidr       = "20.0.0.0/24"
  ip_version = 4
}

resource "openstack_networking_network_v2" "external" {
  name           = var.external_network
  admin_state_up = "true"
  external       = "true"
}

resource "openstack_networking_subnet_v2" "external-subnet" {
  name       = "external-subnet"
  network_id = openstack_networking_network_v2.external.id
  cidr       = "30.0.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "external-router" {
  name                = "external-router"
  admin_state_up      = true
  external_network_id = openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "external-router-interface-1" {
  router_id = openstack_networking_router_v2.external-router.id
  subnet_id = openstack_networking_subnet_v2.internal-subnet.id
}

resource "openstack_networking_floatingip_v2" "fip_1" {
  count = 2
  pool  = openstack_networking_network_v2.external.name
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  count       = 2
  floating_ip = openstack_networking_floatingip_v2.fip_1[count.index].address
  instance_id = openstack_compute_instance_v2.server[count.index].id
}

resource "openstack_blockstorage_volume_v2" "volume" {
  count         = 2
  name          = "my-volume-${count.index}"
  size          = 10  # Taille du volume en gigaoctets
  image_id      = openstack_images_image_v2.ubuntu.id
  availability_zone = "zone-1"
}

resource "openstack_compute_volume_attach_v2" "volume_attach" {
  count        = 2
  instance_id  = openstack_compute_instance_v2.server[count.index].id
  volume_id    = openstack_blockstorage_volume_v2.volume[count.index].id
  device       = "/dev/vdb" 
}

