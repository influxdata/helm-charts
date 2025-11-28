# InfluxDB 3 Enterprise Helm Chart

Official Helm chart for deploying InfluxDB 3 Enterprise on Kubernetes with full workload isolation, high availability, and enterprise features.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Upgrading](#upgrading)
- [Uninstallation](#uninstallation)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Overview

InfluxDB 3 Enterprise is a high-performance time series database designed for production workloads. This Helm chart deploys InfluxDB 3 Enterprise with:

- **Workload Isolation**: Separate nodes for ingestion, querying, compaction, and processing
- **High Availability**: Multiple replicas for ingesters and queriers
- **Horizontal Scalability**: Scale each component independently
- **Enterprise Features**: Processing Engine, multi-node clustering, advanced monitoring
- **Production Ready**: Network policies, service monitors, resource management

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- Object storage (S3, Azure Blob Storage, or Google Cloud Storage)
- PersistentVolume provisioner support (for ingester WAL storage)
- InfluxDB 3 Enterprise license (trial, home, or commercial)
- **NGINX Ingress Controller** (required if using ingress, which is enabled by default)

To install NGINX Ingress Controller:
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

### Optional Components

- **Network Policies**: CNI plugin supporting NetworkPolicy (Calico, Cilium, Weave Net)
- **Monitoring**: Prometheus Operator for ServiceMonitor support

## Installation

### Quick Start

1. **Create namespace:**
   ```bash
   kubectl create namespace influxdb3
   ```

2. **Configure values:**
   ```bash
   # Copy and edit values file
   cp values.yaml my-values.yaml
   # Edit my-values.yaml with your configuration
   ```

3. **Install the chart:**
   ```bash
   helm install influxdb3-enterprise . \
     --namespace influxdb3 \
     -f my-values.yaml
   ```

### Minimum Required Configuration

At minimum, you must configure:

1. **Object Storage** (S3 example):
   ```yaml
   objectStorage:
     type: s3
     bucket: "my-influxdb-bucket"
     s3:
       region: "us-east-1"
       accessKeyId: "YOUR_ACCESS_KEY"
       secretAccessKey: "YOUR_SECRET_KEY"
   ```

2. **License**:
   ```yaml
   license:
     type: "trial"
     email: "your-email@example.com"
     # For commercial licenses use `file: /path/to/license` or `existingSecret`
   ```

3. **Ingress Hosts**:
   ```yaml
   ingress:
     write:
       hosts:
         - host: writes.your-domain.com
     query:
       hosts:
         - host: query.your-domain.com
   ```

## Configuration

### Component Architecture

The chart deploys four main components:

| Component | Purpose | Default Replicas | Scalable |
|-----------|---------|------------------|----------|
| **Ingester** | Handles data writes | 2 | Horizontally |
| **Querier** | Processes queries | 2 | Horizontally |
| **Compactor** | Optimizes storage | 1 | No (single node only) |
| **Processor** | Processing Engine | 0 (disabled) | Horizontally |

### Key Configuration Sections

#### Object Storage

Supports multiple backends:

**Azure Blob Storage:**
```yaml
objectStorage:
  type: azure
  bucket: "my-container"
  azure:
    storageAccount: "myaccount"
    accessKey: "..."
    existingSecret: ""     # optional: secret with storage-account/access-key
```

**Google Cloud Storage:**
```yaml
objectStorage:
  type: google
  bucket: "my-bucket"
  google:
    serviceAccountJson: |
      { "type": "service_account", ... }
    existingSecret: ""     # optional: secret with service-account.json
```

**AWS S3:**
```yaml
objectStorage:
  type: s3
  bucket: "my-bucket"
  s3:
    region: "us-east-1"
    accessKeyId: "..."
    secretAccessKey: "..."
    sessionToken: ""       # optional
    credentialsFile: ""    # optional
    existingSecret: ""     # optional: secret with access-key-id/secret-access-key
```

**MinIO (in-cluster):**
```yaml
objectStorage:
  type: s3
  bucket: "influxdb"
  s3:
    endpoint: "http://minio.minio.svc.cluster.local:9000"
    region: "us-east-1"
    allowHttp: true
    accessKeyId: "minioadmin"
    secretAccessKey: "minioadmin"
    existingSecret: ""
```

**Local Filesystem (dev only):**
```yaml
objectStorage:
  type: file
  # PVC is always created for file storage
  # file:
  #   dataDir: "/var/lib/influxdb3"
  #   persistence:
  #     size: 100Gi
```

#### Resource Configuration

Configure resources per component:

```yaml
ingester:
  resources:
    requests:
      cpu: "4000m"
      memory: "8Gi"
    limits:
      cpu: "8000m"
      memory: "16Gi"
  threads:
    io: 12              # For line protocol parsing
    datafusion: 20      # For WAL snapshots
```

#### TLS

Enable TLS with inline cert/key or an existing secret:

```yaml
tls:
  enabled: true
  cert: |-
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
  key: |-
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----
  # Or reference an existing secret containing tls.crt and tls.key
  existingSecret: influxdb3-tls
```

#### Ingress Configuration

Separate ingresses for write and query traffic:

```yaml
ingress:
  write:
    enabled: true
    className: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    hosts:
      - host: writes.influxdb.example.com
        paths:
          - path: /api/v3/write_lp
            pathType: Prefix
          - path: /api/v2/write
            pathType: Prefix
          - path: /write
            pathType: Prefix
    tls:
      - secretName: influxdb-write-tls
        hosts:
          - writes.influxdb.example.com
```

#### Network Policies

Enable network policies for security:

```yaml
networkPolicy:
  enabled: true
  ingress:
    fromIngressController: true
    fromComponents: true
      egress:
        toDns: true
        toObjectStorage: true
```

**Note**: Requires CNI plugin supporting NetworkPolicy.

#### Pod Disruption Budgets

Each component has an optional PDB controlled by `podDisruptionBudget.enabled` and `maxUnavailable` in `values.yaml`. Defaults are disabled; enable per component or via the command line (e.g., `--set ingester.podDisruptionBudget.enabled=true`).

#### Monitoring

Enable Prometheus ServiceMonitor:

```yaml
serviceMonitor:
  enabled: true
  interval: 30s
  additionalLabels:
    prometheus: kube-prometheus
```

### Processing Engine

Enable the Processing Engine for custom data processing:

```yaml
processingEngine:
  enabled: true
  replicas: 1
  pluginDir: "/plugins"
  persistence:
    enabled: true
    size: "5Gi"
```

## Architecture

### Deployment Topology

```
┌─────────────────────────────────────────────────────────────┐
│                        Ingress Layer                         │
├──────────────────────┬──────────────────────────────────────┤
│  writes.domain.com   │       query.domain.com               │
│         │            │              │                        │
│         ▼            │              ▼                        │
│  ┌──────────────┐    │      ┌──────────────┐               │
│  │  Ingester    │    │      │   Querier    │               │
│  │  Service     │    │      │   Service    │               │
│  └──────┬───────┘    │      └──────┬───────┘               │
│         │            │              │                        │
│    ┌────┴─────┐      │         ┌───┴────┐                  │
│    │          │      │         │        │                   │
│ ┌──▼──┐   ┌──▼──┐   │     ┌──▼──┐ ┌──▼──┐                 │
│ │Pod 0│   │Pod 1│   │     │Pod 0│ │Pod 1│                 │
│ └──┬──┘   └──┬──┘   │     └──┬──┘ └──┬──┘                 │
│    │         │      │         │       │                     │
│    └────┬────┘      │         └───┬───┘                     │
│         │           │             │                          │
│         ▼           │             ▼                          │
│  ┌──────────────────┴─────────────────────┐                │
│  │      Shared Object Storage (S3)        │                │
│  └────────────────┬─────────────────────┬─┘                │
│                   │                     │                   │
│                   ▼                     ▼                   │
│         ┌─────────────────┐   ┌─────────────────┐          │
│         │   Compactor     │   │   Processor     │          │
│         │   (1 replica)   │   │   (optional)    │          │
│         └─────────────────┘   └─────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Write Path**: Client → Ingress → Ingester Service → Ingester Pods → Object Storage
2. **Query Path**: Client → Ingress → Querier Service → Querier Pods → Object Storage
3. **Compaction**: Compactor reads from Object Storage, compacts data, writes back
4. **Processing**: Processor nodes execute plugins on data writes, schedules, or HTTP requests

## Upgrading

### Upgrade the Chart

```bash
helm upgrade influxdb3-enterprise . \
  --namespace influxdb3 \
  -f my-values.yaml
```

### Rolling Updates

StatefulSets perform rolling updates by default. Pods are updated one at a time to ensure availability.

To customize update strategy:

```yaml
ingester:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
```

## Uninstallation

### Delete the Release

```bash
helm uninstall influxdb3-enterprise --namespace influxdb3
```

### Clean Up PVCs

PersistentVolumeClaims are not automatically deleted:

```bash
kubectl delete pvc -n influxdb3 -l app.kubernetes.io/instance=influxdb3-enterprise
```

### Clean Up Namespace

```bash
kubectl delete namespace influxdb3
```

## Examples

See the `examples/` directory for complete configuration examples:

- **values-dev.yaml**: Development setup with local filesystem
- **values-production.yaml**: Production setup with full HA using AWS S3 storage
- **values-minio.yaml**: Using MinIO AIStor storage
- **values-google.yaml**: Using Google Cloud Storage
- **values-azure.yaml**: Using Microsoft Azure blob storage

### Example: Production Deployment

```bash
helm install influxdb3-prod . \
  --namespace influxdb3 \
  --create-namespace \
  -f examples/values-production.yaml
```

## Troubleshooting

### Common Issues

#### Pods Not Starting

Check pod logs:
```bash
kubectl logs -n influxdb3 influxdb3-enterprise-ingester-0
```

Check events:
```bash
kubectl describe pod -n influxdb3 influxdb3-enterprise-ingester-0
```

#### License Issues

Verify license configuration:
```bash
kubectl get secret -n influxdb3 influxdb3-enterprise-license -o yaml
```

#### Object Storage Connection

Test S3 connectivity:
```bash
kubectl run -it --rm debug --image=amazon/aws-cli --restart=Never -- \
  s3 ls s3://your-bucket --region us-east-1
```

#### Ingester WAL Issues

Check PVC status:
```bash
kubectl get pvc -n influxdb3
```

View ingester logs for WAL errors:
```bash
kubectl logs -n influxdb3 influxdb3-enterprise-ingester-0 | grep -i wal
```

### Debug Mode

Enable verbose logs:
```yaml
logs:
  filter: "debug"
```

### Getting Help

- **Documentation**: https://docs.influxdata.com/influxdb3/enterprise/
- **Community**: https://community.influxdata.com/
- **Support**: For Enterprise customers, contact support@influxdata.com
- **Issues**: Report chart issues at https://github.com/influxdata/helm-charts

## Parameters

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cluster.id` | Cluster identifier | `cluster-01` |
| `image.registry` | Image registry | `docker.io` |
| `image.repository` | Image repository | `influxdb` |
| `image.tag` | Image tag | `3-enterprise` |
| `license.type` | trial, home, or commercial | `trial` |
| `license.email` | Email for trial/home | `""` |
| `license.file` | Path to license file (commercial) | `""` |
| `license.existingSecret` | Secret with `license-email` or `license-file` | `""` |

### Object Storage Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `objectStorage.type` | Storage type (s3, azure, google, file) | `s3` |
| `objectStorage.bucket` | Bucket/container name | `influxdb3-enterprise-data` |
| `objectStorage.s3.region` | AWS region | `us-east-1` |
| `objectStorage.s3.endpoint` | S3 endpoint (for S3-compatible) | `""` |
| `objectStorage.s3.accessKeyId` / `secretAccessKey` | S3 credentials | `""` |
| `objectStorage.s3.sessionToken` | Optional session token | `""` |
| `objectStorage.s3.credentialsFile` | Path to credentials file | `""` |
| `objectStorage.s3.existingSecret` | Secret with `access-key-id`/`secret-access-key` | `""` |
| `objectStorage.azure.storageAccount` | Azure storage account | `""` |
| `objectStorage.azure.accessKey` | Azure access key | `""` |
| `objectStorage.azure.existingSecret` | Secret with `storage-account`/`access-key` | `""` |
| `objectStorage.google.serviceAccountJson` | GCS service account JSON (string) | `""` |
| `objectStorage.google.existingSecret` | Secret with `service-account.json` | `""` |

### Component Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingester.replicas` | Number of ingester replicas | `2` |
| `querier.replicas` | Number of querier replicas | `2` |
| `compactor.replicas` | Number of compactor replicas | `1` (fixed) |
| `processingEngine.enabled` | Enable Processing Engine | `false` |
| `*.podDisruptionBudget.enabled` | Enable PDB per component | `false` |
| `*.podDisruptionBudget.maxUnavailable` | Max unavailable when PDB enabled | component-specific |

### TLS Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tls.enabled` | Enable TLS for services | `false` |
| `tls.cert` / `tls.key` | Inline cert/key (used if no existingSecret) | `""` |
| `tls.existingSecret` | Secret with `tls.crt`/`tls.key` | `""` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.write.enabled` / `query.enabled` | Enable write/query ingress | `true` |
| `ingress.*.className` | Ingress class | `nginx` |
| `ingress.*.hosts[0].paths` | Default paths (write: `/api/v3/write_lp`, `/api/v2/write`, `/write`; query: `/api/v3/query`, `/query`, `/`) | as shown |
| `ingress.*.tls` | TLS host/secret list | `[]` |

### Network Policy Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `networkPolicy.enabled` | Enable NetworkPolicies | `false` |
| `networkPolicy.ingress.fromIngressController` | Allow ingress controller | `true` |
| `networkPolicy.ingress.fromComponents` | Allow inter-component traffic | `true` |
| `networkPolicy.egress.toDns` | Allow DNS | `true` |
| `networkPolicy.egress.toObjectStorage` | Allow object storage | `true` |

### Persistence Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingester.persistence.enabled` | Enable WAL PVC | `true` |
| `ingester.persistence.size` | WAL PVC size | `10Gi` |
| `processingEngine.persistence.enabled` | Enable plugins PVC | `true` |
| `objectStorage.type` `file` | Always creates PVC for file storage | — |

### Monitoring Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceMonitor.enabled` | Create ServiceMonitor | `false` |
| `serviceMonitor.namespace` | ServiceMonitor namespace | `""` (release ns) |
| `serviceMonitor.interval` | Scrape interval | `30s` |

See `values.yaml` for complete parameter list.

## License

InfluxDB 3 Enterprise software requires a valid license from InfluxData.
