# v3: Credentials come from spec or local CLI environment (gcloud auth).
# No external scripts, no CP dependencies.
locals {
  spec = var.instance.spec

  project          = local.spec.project
  region           = local.spec.region
  credentials_file = lookup(local.spec, "credentials_file", "")
  credentials_json = lookup(local.spec, "credentials_json", "")

  # Use file-based credentials if provided, else inline JSON, else empty (gcloud auth default)
  credentials = (
    local.credentials_file != "" ? file(local.credentials_file) :
    local.credentials_json != "" ? local.credentials_json :
    ""
  )
}
