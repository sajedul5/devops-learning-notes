terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Credentials are NOT configured here on purpose.
# The provider uses Application Default Credentials (ADC). Authenticate with:
#   gcloud auth application-default login
# or, for CI, export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
# (keep key files out of git — they are matched by .gitignore).
provider "google" {
  project = var.project_id
  region  = var.region
}
