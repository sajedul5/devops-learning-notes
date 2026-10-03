variable "project_id" {
  description = "GCP project ID that owns the VPC."
  type        = string
}

variable "region" {
  description = "Region for the subnetwork."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "vpc-terraform"
}

variable "subnet_cidr" {
  description = "Primary CIDR range of the subnetwork."
  type        = string
  default     = "10.2.0.0/16"
}

variable "secondary_cidr" {
  description = "Secondary CIDR range (e.g. for GKE pods)."
  type        = string
  default     = "192.168.10.0/24"
}
