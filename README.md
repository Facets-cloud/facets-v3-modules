# Facets v3 Modules

Infrastructure as Code modules for **raptor2** — the local-first infrastructure CLI. Provision cloud infrastructure, datastores, Kubernetes resources, and platform tooling across AWS, GCP, and Azure.

```
73 modules  ·  3 clouds  ·  local-first
```

## Getting Started

### 1. Add as a Module Source

```bash
raptor2 set module-source --name facets --type git \
  --url https://github.com/Facets-cloud/facets-v3-modules.git \
  --path modules --ref main
```

### 2. Discover Modules

```bash
# List all available modules
raptor2 get modules

# Describe a specific module (inputs, outputs, spec schema)
raptor2 describe module postgres/aws-rds/1.0 -o json

# Search output types (for wiring between modules)
raptor2 search types
raptor2 describe type @facets/kubernetes-details
```

### 3. Use in a Project

```bash
# Create a resource from a module
raptor2 apply resource cloud_account/aws_provider/1.0 -p my-app -n default
raptor2 apply resource network/aws_network/1.0 -p my-app -n main-vpc \
  --input cloud_account=cloud_account/default

# Preview deployment
raptor2 apply environment -p my-app -e dev --plan

# Deploy
raptor2 apply environment -p my-app -e dev
```

---

## Module Catalog

### AWS

EKS clusters, Karpenter autoscaling, ALB, managed RDS, Aurora, DocumentDB, ElastiCache, MSK, and full Kubernetes platform tooling.

<details>
<summary><strong>What's included</strong></summary>

**Infrastructure**
`Cloud Account (aws_provider)` `Network/VPC (aws_network)` `EKS Standard (eks_standard)` `Node Pool/Karpenter (karpenter)` `Karpenter (default)` `AWS ALB Controller (standard)` `ALB (aws)` `Service (aws)` `S3 (standard)` `SQS (standard)` `SNS (standard)` `DNS Zone (aws)` `ECS Fargate (aws)` `Static Site (aws)` `Storage Class (aws_ebs)`

**Managed Datastores**
`PostgreSQL/RDS (aws-rds)` `PostgreSQL/Aurora (aws-aurora)` `MySQL/RDS (aws-rds)` `MySQL/Aurora (aws-aurora)` `MongoDB/DocumentDB (aws-documentdb)` `Redis/ElastiCache (aws-elasticache)` `Kafka/MSK (aws-msk)`

**Self-hosted via KubeBlocks**
`PostgreSQL` `MySQL` `MongoDB` `Redis`

**K8s Platform**
`Helm` `Ingress/Gateway Fabric` `Ingress/NGINX` `cert-manager` `ConfigMap` `Secrets` `PVC (k8s_standard)` `K8s Resources` `Gateway API CRD` `VPA` `Artifactories`

**Operators & Monitoring**
`KubeBlocks` `Strimzi` `ECK` `WireGuard Operator` `WireGuard VPN` `Alert Rules` `Prometheus` `Grafana` `Monitoring`

</details>

---

### GCP

GKE clusters, Cloud SQL, Memorystore, Pub/Sub, Workload Identity, and full Kubernetes platform tooling.

<details>
<summary><strong>What's included</strong></summary>

**Infrastructure**
`Cloud Account (gcp_provider)` `Network/VPC (gcp_network)` `GKE (gke)` `Node Pool (gcp)` `Node Fleet (gcp_node_fleet)` `Service (gcp)` `Workload Identity (gcp)` `Pub/Sub (gcp)`

**Managed Datastores**
`PostgreSQL/Cloud SQL (gcp-cloudsql)` `MySQL/Cloud SQL (gcp-cloudsql)` `Redis/Memorystore (gcp-memorystore)` `Kafka/MSK (gcp-msk)` `Kafka Topic (gcp-msk)`

**Self-hosted via KubeBlocks**
`PostgreSQL` `MySQL` `MongoDB` `Redis`

**K8s Platform**
`Helm` `Ingress/Gateway Fabric` `cert-manager` `ConfigMap` `Secrets` `PVC (k8s_standard)` `K8s Resources` `Gateway API CRD` `VPA` `Artifactories`

**Operators & Monitoring**
`KubeBlocks` `Strimzi` `ECK` `WireGuard Operator` `WireGuard VPN` `Alert Rules` `Prometheus` `Grafana` `Monitoring`

</details>

---

### Azure

AKS clusters, Flexible Server (Postgres/MySQL), Cosmos DB, Azure Cache, Workload Identity, and full Kubernetes platform tooling.

<details>
<summary><strong>What's included</strong></summary>

**Infrastructure**
`Cloud Account (azure_provider)` `Network/VNet (azure_network)` `AKS (aks)` `Node Pool (azure)` `Service (azure)` `Workload Identity (azure)`

**Managed Datastores**
`PostgreSQL/Flexible Server (azure-flexible-server)` `MySQL/Flexible Server (azure-flexible-server)` `MongoDB/Cosmos DB (cosmosdb)` `Redis/Azure Cache (azure_cache_custom)`

**Self-hosted via KubeBlocks**
`PostgreSQL` `MySQL` `MongoDB` `Redis`

**K8s Platform**
`Helm` `Ingress/Gateway Fabric` `cert-manager` `ConfigMap` `Secrets` `PVC (k8s_standard)` `K8s Resources` `Gateway API CRD` `VPA` `Artifactories`

**Operators & Monitoring**
`KubeBlocks` `Strimzi` `ECK` `WireGuard Operator` `WireGuard VPN` `Alert Rules` `Prometheus` `Grafana` `Monitoring`

</details>

---

## Module Development

### Repository Structure

```
modules/{intent}/{flavor}/{version}/        Core infrastructure modules
modules/datastore/{tech}/{flavor}/{version}/ Database modules
outputs/{type-name}/                        Output type schemas (@facets/*)
icons/{intent}.svg                          Module icons (cloud-neutral)
rules.md                                    Validation rules
```

### Module Files

| File | Purpose |
|------|---------|
| `facets.yaml` | Module definition (spec schema, inputs, outputs, sample) |
| `variables.tf` | `var.instance` (spec) and `var.inputs` (dependencies) |
| `main.tf` | Terraform resources |
| `locals.tf` | `output_attributes` and `output_interfaces` |
| `outputs.tf` | Terraform outputs |

### Validation

```bash
# Validate a single module
raptor2 validate-module KIND/FLAVOR/VERSION

# Validate and seal all modules
raptor2 validate-all
```

See **rules.md** for the complete validation ruleset with examples.

### Contributing

```bash
# Preview type changes + impact analysis (no PR):
raptor2 contribute module KIND/FLAVOR/VERSION --dry-run

# Contribute via PR:
raptor2 contribute module KIND/FLAVOR/VERSION
```

---

## Links

- [raptor2 CLI releases](https://github.com/Facets-cloud/raptor2-releases)
- [Facets](https://facets.cloud)
