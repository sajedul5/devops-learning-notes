resource "google_folder" "my_folder" {
  display_name = var.folder_name
  parent       = "organizations/${var.org_id}"
}
