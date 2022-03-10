resource "random_string" "test_string" {
    length           = 12
    upper            = false
    special          = false
    lower            = true
    number           = false
}
locals {
  name = random_string.test_string.id
}
provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_instance" "test_instance" {
  name         = "vm-${local.name}"
  machine_type = "f1-micro"
  zone         = "${var.region}-a"
  tags         = ["test"]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = google_compute_network.test_net.id
    subnetwork = google_compute_subnetwork.test_subnet.id
    access_config {
      
    }
  }
  
  metadata_startup_script = file("welcomemsg.sh")

  service_account {
    email =  google_service_account.test_sa.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_network" "test_net" {
    name = "network-${local.name}"
    auto_create_subnetworks = var.auto_create_subnetworks
}
resource "google_compute_subnetwork" "test_subnet" {
    name = "subnetwork-${local.name}"
    region = var.region
    network = google_compute_network.test_net.id
    ip_cidr_range = "10.1.0.0/29"
}
resource "google_compute_firewall" "test_firewall" {
    name = "firewall-${local.name}"
    network = google_compute_network.test_net.id
    allow {
      protocol = "tcp"
      ports     = ["80"]
    }
    source_tags = ["test"]
}
resource "google_service_account" "test_sa" {
    count        = var.service_account_create?1:0
    account_id   = "serviceaccount-${local.name}-id"
    project      = var.project
    display_name = local.name
}