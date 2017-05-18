# define cloud-init files and resolve variables from terraform
data "template_file" "init_mediawiki" {
    template = "${file("init_mediawiki")}"
	vars {
    	public_ip = "${openstack_networking_floatingip_v2.fip_loadbalancer.address}"
		database_ip = "${openstack_compute_instance_v2.database.access_ip_v4}"
		monitoring-ip = "${openstack_compute_instance_v2.monitoring.access_ip_v4}"
  	}
}
data "template_file" "init_database" {
    template = "${file("init_database")}"
	vars {
		monitoring-ip = "${openstack_compute_instance_v2.monitoring.access_ip_v4}"
	}
}
data "template_file" "init_loadbalancer" {
    template = "${file("init_loadbalancer")}"
	vars {
    	server1_ip = "${openstack_compute_instance_v2.mediawiki-1.access_ip_v4}"
		server2_ip = "${openstack_compute_instance_v2.mediawiki-2.access_ip_v4}"
		server3_ip = "${openstack_compute_instance_v2.mediawiki-3.access_ip_v4}"
		monitoring-ip = "${openstack_compute_instance_v2.monitoring.access_ip_v4}"
  	}
}
data "template_file" "init_monitoring" {
    template = "${file("init_monitoring")}"
}

# create first mediawiki instance
resource "openstack_compute_instance_v2" "mediawiki-1" {
	name = "mediawiki-1"
	image_name = "Ubuntu Server 14.04 RAW"
	flavor_name = "m1.small"
	key_pair = "christopher-uulm"
	security_groups = ["default"]
	region	= "Ulm"
	network {
		uuid = "${openstack_networking_network_v2.private-net.id}"
	}
	user_data = "${data.template_file.init_mediawiki.rendered}"
}

# create second mediawiki instance
resource "openstack_compute_instance_v2" "mediawiki-2" {
	name = "mediawiki-2"
	image_name = "Ubuntu Server 14.04 RAW"
	flavor_name = "m1.small"
	key_pair = "christopher-uulm"
	security_groups = ["default"]
	region	= "Ulm"
	network {
		uuid = "${openstack_networking_network_v2.private-net.id}"
	}
	user_data = "${data.template_file.init_mediawiki.rendered}"
}

# create third mediawiki instance
resource "openstack_compute_instance_v2" "mediawiki-3" {
	name = "mediawiki-3"
	image_name = "Ubuntu Server 14.04 RAW"
	flavor_name = "m1.small"
	key_pair = "christopher-uulm"
	security_groups = ["default"]
	region	= "Ulm"
	network {
		uuid = "${openstack_networking_network_v2.private-net.id}"
	}
	user_data = "${data.template_file.init_mediawiki.rendered}"
}

# create database server
resource "openstack_compute_instance_v2" "database" {
	name = "database"
	image_name = "Ubuntu Server 16.04 RAW"
	flavor_name = "m1.nano"
	key_pair = "christopher-uulm"
	security_groups = ["default"]
	region	= "Ulm"
	network {
		uuid = "${openstack_networking_network_v2.private-net.id}"
	}
	user_data = "${data.template_file.init_database.rendered}"
}

# create loadbalancer
resource "openstack_compute_instance_v2" "loadbalancer" {
	name = "loadbalancer"
	image_name = "Ubuntu Server 16.04 RAW"
	flavor_name = "m1.nano"
	key_pair = "christopher-uulm"
	security_groups = ["default"]
	region	= "Ulm"
	network {
		uuid = "${openstack_networking_network_v2.private-net.id}"
	}
	user_data = "${data.template_file.init_loadbalancer.rendered}"
}

# create monitoring
resource "openstack_compute_instance_v2" "monitoring" {
	name = "monitoring"
	image_name = "Ubuntu Server 16.04 RAW"
	flavor_name = "m1.small"
	key_pair = "christopher-uulm"
	security_groups = ["default", "monitoring"]
	region	= "Ulm"
	network {
		uuid = "${openstack_networking_network_v2.private-net.id}"
	}
	user_data = "${data.template_file.init_monitoring.rendered}"
}

# create floating ip for loadbalancer
resource "openstack_networking_floatingip_v2" "fip_loadbalancer" {
  pool = "routed"
  region = "Ulm"  
}

# attach floating ip to loadbalancer vm
resource "openstack_compute_floatingip_associate_v2" "fip_loadbalancer" {
  floating_ip = "${openstack_networking_floatingip_v2.fip_loadbalancer.address}"
  instance_id = "${openstack_compute_instance_v2.loadbalancer.id}"
  region = "Ulm"
}

# print floating ip of loadbalancer to user
output "loadbalancer_floating_ip" {
  value = "${openstack_networking_floatingip_v2.fip_loadbalancer.address}"
}

# create floating ip for monitoring
resource "openstack_networking_floatingip_v2" "fip_monitoring" {
  pool = "routed"
  region = "Ulm"  
}

# attach floating ip to loadbalancer vm
resource "openstack_compute_floatingip_associate_v2" "fip_monitoring" {
  floating_ip = "${openstack_networking_floatingip_v2.fip_monitoring.address}"
  instance_id = "${openstack_compute_instance_v2.monitoring.id}"
  region = "Ulm"
}

# print floating ip of monitoring to user
output "monitoringr_floating_ip" {
  value = "${openstack_networking_floatingip_v2.fip_monitoring.address}"
}