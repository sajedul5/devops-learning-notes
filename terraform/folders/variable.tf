variable "org_id" {
  description = "Numeric GCP organization ID (gcloud organizations list). Keep it in terraform.tfvars, not in code."
  type        = string
}

variable "folder_name" {
  description = "Display name of the folder to create."
  type        = string
  default     = "RnD-GCP-tf"
}
