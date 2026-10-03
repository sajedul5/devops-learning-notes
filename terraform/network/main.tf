resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = "terraform-subnetwork"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id

  # Lets VMs without external IPs reach Google APIs privately.
  private_ip_google_access = true

  # Optional: VPC flow logs help security investigations (note: they cost money).
  # log_config {
  #   aggregation_interval = "INTERVAL_10_MIN"
  #   flow_sampling        = 0.5
  #   metadata             = "INCLUDE_ALL_METADATA"
  # }

  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = var.secondary_cidr
  }
}

# The resource was renamed from its old address; this keeps existing state intact.
moved {
  from = google_compute_subnetwork.network-with-private-secondary-ip-ranges
  to   = google_compute_subnetwork.subnet
}

output "network_id" {
  value = google_compute_network.vpc_network.id
}
