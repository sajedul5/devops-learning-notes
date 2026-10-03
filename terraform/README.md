# Terraform on GCP: VPC with modules

Creates a custom-mode VPC (`vpc-terraform`) and a subnetwork with a secondary range
(useful for GKE pods). Shows **root module → child modules**, input variables and outputs.

```
terraform/
├── provider.tf               # provider + version constraints (no credentials!)
├── variables.tf              # project_id, region
├── main.tf                   # calls ./network (and optionally ./folders)
├── terraform.tfvars.example  # copy to terraform.tfvars (git-ignored)
├── network/                  # VPC + subnet module
└── folders/                  # GCP folder module (needs org-level permissions)
```

## Usage

```bash
# 1. Authenticate (Application Default Credentials, so no key file in the repo)
gcloud auth application-default login

# 2. Configure
cp terraform.tfvars.example terraform.tfvars    # set project_id

# 3. Run
terraform init
terraform fmt -check && terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# 4. Clean up when done (avoid surprise bills)
terraform destroy
```

## Security & good practices
- **No credentials in code.** The provider uses ADC. In CI use Workload Identity
  Federation or `GOOGLE_APPLICATION_CREDENTIALS` pointing to a key stored as a CI secret.
- Use a **least-privilege service account** (e.g. `roles/compute.networkAdmin`),
  not your personal Owner/org-admin account.
- `*.tfstate` contains resource details in plain text and is git-ignored. For teams use a
  remote backend with locking and encryption:
  ```hcl
  terraform {
    backend "gcs" {
      bucket = "my-tf-state-bucket"   # enable object versioning on the bucket
      prefix = "devops/network"
    }
  }
  ```
- `private_ip_google_access` is enabled so VMs without public IPs can still reach Google APIs.
- Scan before applying: `checkov -d .` or `trivy config .`.
