variable "name" {
  description = "The name of the service you are running"
}

variable "role" {
  description = "The puppet role this particular machine will use"
}

variable "puppet_master_name" {
  description = "The fqdn of the puppet master"
}

variable "location" {
  description = "The location of this node - will be used to complete fqdn"
  default = "infrastructure"
}

variable "puppet_master_ip" {
  description = "The IP address of the puppet master"
}

resource "openstack_networking_floatingip_v2" "floating_ip" {
  pool = "ext-net-pdx1-opdx1"
}

variable "openstack_keypair" {
  type        = "string"
  description = "The keypair to be used."
  default     = "james_jones"
}

variable "tenant_network" {
  type        = "string"
  description = "The network to be used."
  default     = "infrastructure_network"
}

data "template_file" "init_node" {
  template = "${file("../scripts/bootstrap_windows_agent.tpl")}"

  vars {
    role        = "${var.role}"
    dnssuffix   = "infrastructure.lab"
    master_name = "${var.puppet_master_name}"
    masterip    = "${var.puppet_master_ip}"
  }
}

resource "openstack_compute_instance_v2" "windows_node" {
  name              = "${var.name}.infrastructure.lab"
  image_name        = "windows_2012_r2_std_eval_x86_64"
  availability_zone = "opdx1"
  flavor_name       = "g1.large"
  key_pair          = "${var.openstack_keypair}"
  security_groups   = ["default", "sg0"]

  network {
    name           = "${var.tenant_network}"
    access_network = true
  }

  user_data = "${data.template_file.init_node.rendered}"
}

resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.floating_ip.address}"
  instance_id = "${openstack_compute_instance_v2.windows_node.id}"
}
