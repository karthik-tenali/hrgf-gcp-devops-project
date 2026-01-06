# -----------------------------
# VPC Network
# -----------------------------
resource "google_compute_network" "vpc" {
  name                    = "hrgf-vpc"
  auto_create_subnetworks = false
}

# -----------------------------
# Subnet (with secondary ranges)
# -----------------------------
resource "google_compute_subnetwork" "subnet" {
  name          = "hrgf-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.0.0/24"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# -----------------------------
# GKE Cluster (Control Plane)
# -----------------------------
resource "google_container_cluster" "primary" {
  name     = "hrgf-gke-cluster"
  location = var.zone
  deletion_protection = false

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# -----------------------------
# GKE Node Pool
# -----------------------------
resource "google_container_node_pool" "primary_nodes" {
  name       = "hrgf-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "e2-small"
    disk_size_gb = 15

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "dev"
      managed_by  = "terraform"
    }

    tags = ["gke-node"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# -----------------------------
# Artifact Registry (Docker)
# -----------------------------
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "hrgf-app"
  description   = "Docker images for HRGF application"
  format        = "DOCKER"
}

