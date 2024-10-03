resource "google_folder" "my_folder" {
  display_name = "RnD-GCP-tf"
  parent       = "organizations/000000000000"
}
