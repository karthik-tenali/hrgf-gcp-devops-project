output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

output "zone" {
  description = "GCP Zone"
  value       = var.zone
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

output "gke_cluster_name" {
  description = "GKE Cluster name"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_location" {
  description = "GKE Cluster location"
  value       = google_container_cluster.primary.location
}

output "artifact_registry_repo" {
  description = "Artifact Registry repository ID"
  value       = google_artifact_registry_repository.docker_repo.repository_id
}

output "artifact_registry_url" {
  description = "Artifact Registry Docker URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}
