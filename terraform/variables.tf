variable "external_network" {
  type        = string
  default     = "external"
  description = "A public network to expose our instances"
}

variable "internal_network" {
  type        = string
  default     = "internal"
  description = "A private network in order to deploy our instances"
}

variable "region_name" {
  description = "Openstack region name for resources"
}
