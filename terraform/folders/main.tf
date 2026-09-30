resource "google_folder" "my_folder" {
  display_name = "RnD-GCP-tf"
  parent       = "organizations/${var.org_id}"
}
