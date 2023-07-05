# TP - OPENSTACK / TERRAFORM

## Enzo SBOREA - Clément MATRAY

### Schéma réseau de la structure
https://github.com/enzosborea/tpcloud/blob/main/Sche%CC%81ma-TP.png

### Connexion via VPN

Pour réaliser ce TP, nous avons utilisé une connexion VPN sur un routeur pour accéder à une machine permettant de faire de la virtualisation.

### Mise en place des VMs
Création de deux VMs sur VirtualBox :

**Unbuntu Terraform**
- CPU 1
- RAM 4GB
- Réseau Bridge : 10.0.20.25/27
- Stockage : 40GB

**Ubuntu Openstack**
- CPU 4
- RAM 10GB
- Réseau carte bridge : 10.0.20.16/27
- Réseau carte externe : 30.0.0.4/24
- Réseau carte interne : 20.0.0.4/24
- Stockage : 80GB


Téléchargement de l’ISO Ubuntu 22.04 LTS (https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso)

### Création du repo GitHub

Le repository permet de versionner notre code, ci-dessous le lien de ce repository. https://github.com/enzosborea/tpcloud/tree/main/terraform

### Installation d’openstack

Nous avons utilisé la documentation suivante https://docs.openstack.org/devstack/latest/ pour l’installation d’openstack.

### Installation de terraform

Nous avons utilisé la documentation suivante https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli pour l’installation de terraform.

### Déploiement d’instance sur OpenStack (Terraform)

Afin de déployer des instances, des réseaux et des volumes, nous avons créé plusieurs fichiers terraform.

**provider.tf**

```hcl
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
  tenant_name = "admin"
  password    = "tpcloud"
  auth_url    = "http://10.0.20.16/identity"
  region      = var.region_name
}
```

 Ce fichier permet d’utiliser la solution openstack et d’interagir avec celui-ci via une URL d’authentification.

**variables.tf**

```hcl
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
```

Ce fichier permet de déclarer des variables pour le réseau externe, interne et la région de notre openstack.

```hcl
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
```

Ce fichier à plusieurs fonctions, celui-ci permet de créer une image Ubuntu 22.04 LTS en format qcow2 permettant d’instancier nos VMs, d’instancier deux VMs à partir de ce fichier avec une flavor (m1.small), de créer nos volumes et de les attacher pour ces machines, de créer nos réseaux internes et externes et d’assigner des IPs flottantes.

Une fois ce ce code terraform déployé avec la commande `terraform apply`, nous obtenons sur notre openstack les ressources suivantes :