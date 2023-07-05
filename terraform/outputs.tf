output "server_private_ip" {
  value = openstack_compute_instance_v2.server.access_ip_v4
}
output "server_floating_ip" {
  value = openstack_networking_floatingip_v2.fip_1.address
}