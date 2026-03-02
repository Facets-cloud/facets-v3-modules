# GCP Cloud Account Module (v3 Local-First)

Configures GCP provider credentials for downstream modules. Works entirely
locally with no Control Plane dependency.

## Progressive Authentication

### Level 0: gcloud CLI (zero config)

Leave `credentials_file` and `credentials_json` empty. Terraform uses your
local Application Default Credentials:

```bash
gcloud auth application-default login
```

```yaml
spec:
  project: my-project-id
  region: us-central1
```

### Level 1: Service Account Key File

Point to a JSON key file on disk:

```yaml
spec:
  project: my-project-id
  region: us-central1
  credentials_file: /path/to/service-account.json
```

### Level 2: Inline JSON Credentials

Embed the service account key directly (use `raptor2 create secret` for
production):

```yaml
spec:
  project: my-project-id
  region: us-central1
  credentials_json: '{"type":"service_account","project_id":"...","private_key":"..."}'
```

## Output Type

`@facets/gcp_cloud_account` with attributes:

| Attribute    | Description                                       |
|--------------|---------------------------------------------------|
| project_id   | GCP project ID                                    |
| project      | GCP project ID (alias for backward compatibility) |
| credentials  | Service account JSON (sensitive, empty if CLI)    |
| region       | GCP region                                        |
| secrets      | List of sensitive attribute names                 |
