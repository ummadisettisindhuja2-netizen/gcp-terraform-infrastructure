terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "devops_vpc" {
  name                    = "devops-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "devops_subnet" {
  name          = "devops-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.devops_vpc.id
}

resource "google_compute_firewall" "allow_http_ssh" {
  name    = "allow-http-ssh"
  network = google_compute_network.devops_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_instance" "web_server" {
  name         = "terraform-web-server"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.devops_subnet.id

    access_config {}
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    systemctl enable apache2
    systemctl start apache2
    echo "<h1>Deployed on GCP using Terraform</h1>" > /var/www/html/index.html
  SCRIPT
}
