# Uncomment to also create a GCP folder (requires organization-level permissions).
# module "folders" {
#   source      = "./folders"
#   org_id      = var.org_id
#   folder_name = "RnD-GCP-tf"
# }

module "network" {
  source     = "./network"
  project_id = var.project_id
  region     = var.region
}
