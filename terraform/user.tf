resource "openstack_identity_project_v3" "project-tpcloud" {
  name        = "project-tpcloud"
  description = "Projet TP Cloud"
}

resource "openstack_identity_user_v3" "tpcloud_user" {
  name      = "tpcloud"
  password  = "tpcloud"
  domain_id = "default"
  default_project_id = openstack_identity_project_v3.project-tpcloud.id
}

resource "openstack_identity_role_assignment_v3" "admin" {
  user_id    = openstack_identity_user_v3.tpcloud_user.id
  project_id = openstack_identity_project_v3.project-tpcloud.id
  role_id    = "ee48aa20a248401ba3d1141de8916a60"
}

