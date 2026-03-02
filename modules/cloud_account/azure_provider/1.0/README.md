# Azure Cloud Account Module

## Overview

Configures Azure provider credentials for downstream modules. Supports progressive authentication: use `az login` defaults for local development (Level 0) or provide explicit service principal credentials for CI/production (Level 1).

## Authentication Levels

### Level 0: az login (zero config)

Run `az login` locally. The module passes `subscription_id` and leaves other fields empty, so the Azure provider falls back to CLI-based authentication.

### Level 1: Service Principal

Provide `client_id`, `client_secret`, and `tenant_id` in the resource spec for explicit service principal authentication. Use `raptor2 create secret` for production secrets.

## Configurability

- **subscription_id** (required): Azure subscription ID
- **tenant_id** (optional): Azure AD tenant ID
- **client_id** (optional): Service principal application/client ID
- **client_secret** (optional): Service principal secret

## Usage

```yaml
kind: cloud_account
flavor: azure_provider
version: "1.0"
spec:
  subscription_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

For service principal authentication:

```yaml
kind: cloud_account
flavor: azure_provider
version: "1.0"
spec:
  subscription_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_secret: "${secret:azure_client_secret}"
```
