# module "folders" {
#   source = "./folders"
#   org_id = var.org_id
# }

module "network" {
  source     = "./network"
  project_id = var.project_id
}
