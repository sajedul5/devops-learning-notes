provider "google" {
  project = var.project_id
  region  = var.region
  # Credentials come from the environment, never from the repo:
  #   gcloud auth application-default login
  #   or export GOOGLE_APPLICATION_CREDENTIALS=/path/outside/repo/key.json
}
