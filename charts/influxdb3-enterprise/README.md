# InfluxDB 3 Enterprise Helm Chart

Official Helm chart for deploying InfluxDB 3 Enterprise on Kubernetes with full workload isolation, high availability, and enterprise features.

**Chart Version:** 0.9.0  
**App Version:** 3.11.0  
**Storage Engine:** PachaTree (new clusters), Parquet (existing clusters, migration available)

## Table of Contents

- [Overview](#overview)
- [What's New in 0.9.0](#whats-new-in-090)
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
- **PachaTree Storage Engine**: Next-generation storage with improved compaction performance (3.11+)
- **Enterprise Features**: Processing Engine, multi-node clustering, advanced monitoring
- **Production Ready**: Network policies, service monitors, resource management

## What's New in 0.9.0

This release updates the chart to support InfluxDB 3.11.0 with new features and improvements:

### 🆕 New Features

- **PachaTree Storage Engine**: Next-generation storage engine with improved compaction performance
  - New clusters automatically use PachaTree
  - Existing Parquet clusters can migrate via `engine.upgradePachaTree: true`
  - See [MIGRATION-3.11.md](./MIGRATION-3.11.md) for migration guide

- **Graceful Shutdown**: Configurable connection drain timeout
  ```yaml
  shutdown:
    timeout: "30s"  # Default: 30s, 0s=skip drain
  ```

- **Processing Engine Updates**:
  - `disablePackageManagement`: Lock down package installations
  - `asyncTriggerConcurrencyLimit`: Control async trigger concurrency

### ⚙️ Breaking Changes

**Mostly backward compatible** - existing Enterprise env aliases continue to work with warnings, but PachaTree `PT_` option names must be updated for 3.11.

- Enterprise environment variables renamed (`INFLUXDB3_ENTERPRISE_*` → `INFLUXDB3_*`)
  - Old names still work with deprecation warnings
- PachaTree environment variables renamed (`INFLUXDB3_PT_*` -> `INFLUXDB3_*`)
  - Old `PT_` names are ignored by InfluxDB 3.11
- 3 WAL variables renamed (old names still work)
- 1 memory variable renamed with format change (now requires units: `"2GB"`)
- 2 deprecated options removed:
  - `objectStorage.cacheEndpoint` (now automatic)
  - `dataLifecycle.hardDeleteDefaultDuration` (cluster-level only)

**See:** [MIGRATION-3.11.md](./MIGRATION-3.11.md) for complete upgrade guide.

### 📦 Container Images

**Quay.io (Recommended):**
```yaml
image:
  registry: quay.io
  repository: influxdb/influxdb3-enterprise
  tag: "e5242f505d23039a340d21693a994b1a053b0f15"  # 3.11.0
```

**Docker Hub:**
```yaml
image:
  registry: docker.io
  repository: influxdb/influxdb3-enterprise
  tag: "3.11.0-enterprise"
```

**Direct Downloads (non-containerized):**
- [x86_64 RPM](https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise-3.11.0.x86_64.rpm)
- [aarch64 RPM](https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise-3.11.0.aarch64.rpm)
- [amd64 DEB](https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise_3.11.0-1_amd64.deb)
- [arm64 DEB](https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise_3.11.0-1_arm64.deb)

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- Object storage (S3, Azure Blob Storage, or Google Cloud Storage)
- RWX PersistentVolume provisioner support when using `objectStorage.type=file`
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

3. **Ingress Host**:
   ```yaml
   ingress:
     host: "influxdb.example.com"
     # Optional Flight host override (defaults to ingress.host)
     flight:
       host: ""
   ```

### Preconfigured Admin Token

Use this when you want the cluster to start with a known offline-generated admin token.

1. Generate an offline admin token file:
   ```bash
   influxdb3 create token --admin --name bootstrap-admin --expiry 365d --offline --output-file admin-token.json
   ```

2. Create a Kubernetes secret from that file:
   ```bash
   kubectl -n influxdb3 create secret generic influxdb3-admin-token \
     --from-file=admin-token.json=admin-token.json
   ```

3. Configure the chart:
   ```yaml
   security:
     auth:
       adminToken:
         existingSecret: influxdb3-admin-token
   ```

Notes:
- Secret key must be `admin-token.json`.
- The chart mounts it at `/etc/influxdb/admin-token/admin-token.json`.
- `security.auth.adminToken.existingSecret` and `security.auth.adminToken.file` are mutually exclusive.
- If using `security.auth.adminToken.file`, ensure that path exists inside the container (for example via `extraVolumes`/`extraVolumeMounts`).
- `security.auth.adminToken.recovery.httpBind` enables an unauthenticated recovery endpoint. Use only when necessary and keep it accessible only from trusted networks.
- See: https://docs.influxdata.com/influxdb3/enterprise/reference/config-options/#admin-token-recovery-http-bind

### Preconfigured Permission Tokens

Use this when you want the cluster to start with known offline-generated permission tokens.

1. Generate an offline permission tokens file:
   ```bash
   influxdb3 create token \
     --name "bootstrap-token" \
     --permission "db:db1,db2:read,write" \
     --permission "db:db3:read" \
     --expiry 365d \
     --offline \
     --create-databases db1,db2 \
     --output-file permission-tokens.json
   ```
2. Create a Kubernetes secret from that file:
   ```bash
   kubectl -n influxdb3 create secret generic influxdb3-permission-tokens \
     --from-file=permission-tokens.json=permission-tokens.json
   ```
3. Configure the chart:
   ```yaml
   security:
     auth:
       permissionTokens:
         existingSecret: influxdb3-permission-tokens
   ```

Notes:
- Secret key must be `permission-tokens.json`.
- The chart mounts it at `/etc/influxdb/permission-tokens/permission-tokens.json`.
- `security.auth.permissionTokens.existingSecret` and `security.auth.permissionTokens.file` are mutually exclusive.
- See: https://docs.influxdata.com/influxdb3/enterprise/reference/config-options/#permission-tokens-file

## Configuration

### Storage Engine (PachaTree)

**New in 3.11:** InfluxDB 3 Enterprise supports two storage engines:

| Engine | Description | Best For | Default |
|--------|-------------|----------|---------|
| **PachaTree** | Next-gen storage with improved compaction | New clusters, production workloads | ✅ New clusters (3.11+) |
| **Parquet** | Previous-gen storage engine | Existing clusters, legacy compatibility | Existing clusters |

#### For New Clusters

**No configuration needed** - PachaTree is automatically enabled:

```yaml
# values.yaml for new cluster
cluster:
  id: "my-cluster"

objectStorage:
  type: s3
  bucket: "my-bucket"
  # ...

# PachaTree is automatically enabled - no configuration required
```

#### For Existing Parquet Clusters

**Stay on Parquet** (recommended until you're ready to migrate):

```yaml
# No configuration changes needed
# Cluster stays on Parquet after upgrading to chart 0.9.0
```

**Migrate to PachaTree** (opt-in, one-time, one-way):

```yaml
# Enable PachaTree migration
engine:
  upgradePachaTree: true    # Set ONCE to start migration, then remove after completion
  
  # Optional: Tune PachaTree behavior
  pachaTree:
    shardCount: 2                    # More shards = more parallelism (default: 1)
    maxTotalColumns: 10000           # Higher column limit (default: 5000)
    snapshotSize: 200000             # Larger snapshot threshold (default: 100000)
    gen0MaxFileSize: "200mb"         # Larger Gen0 files (default: "100mb")
    walReplicaQueueLength: 2000      # Larger WAL queue (default: 1000)
```

**⚠️ Migration Notes:**
- Migration is **one-way** (Parquet → PachaTree, no rollback)
- Cluster stays online during migration
- Duration varies by data volume (hours to days)
- See [MIGRATION-3.11.md](./MIGRATION-3.11.md) for detailed migration guide

#### PachaTree Benefits

- ✅ **Better compaction throughput** - Time-disjoint two-level compaction
- ✅ **Improved ingest performance** - Especially for leading-edge writes
- ✅ **Reduced WAL lag** - Better handling of write spikes
- ✅ **Better query performance** - On recent data

### Graceful Shutdown

**New in 3.11:** Configure connection drain timeout before pod shutdown:

```yaml
shutdown:
  timeout: "30s"    # Drain connections for 30s before forcibly closing (default)
  # timeout: "60s"  # Longer timeout for production
  # timeout: "0s"   # Skip drain entirely (immediate shutdown)
```

**Benefits:**
- Fewer client connection errors during rolling updates
- Better user experience during maintenance
- Reduced load on ingress/load balancers

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
  file:
    dataDir: "/var/lib/influxdb3"
    persistence:
      accessMode: ReadWriteMany
      size: 100Gi
```

For `objectStorage.type=s3`, `google`, or `azure`, the chart does not create a
data or WAL PVC. WAL files, snapshots, catalog data, and Parquet files are
persisted through the configured durable object store.

For `objectStorage.type=memory` or `memory-throttled`, all object-store data
(WAL files, snapshots, catalog data, and Parquet files) is held in memory and
lost when the pod restarts. These modes are intended for testing only.

For `objectStorage.type=file`, the chart creates one shared RWX object-storage
PVC and mounts it at `objectStorage.file.dataDir` for Enterprise components.
For single-node local testing only, where all pods run on the same node, you can
set `objectStorage.file.persistence.accessMode=ReadWriteOnce` to use a
local-path style StorageClass.

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
  numIOThreads: 12
  datafusion:
    numThreads: 20
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

The chart creates separate ingresses for write, query, and Flight/gRPC traffic:

```yaml
ingress:
  enabled: true
  className: "nginx"
  host: "influxdb.example.com"
  tls:
    - secretName: influxdb-tls
      hosts:
        - influxdb.example.com

  write:
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "100m"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"

  query:
    annotations:
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"

  # Flight/gRPC ingress to querier
  flight:
    host: "" # Optional override; defaults to ingress.host
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
```

Route summary:
- Write ingress routes `/api/v3/write_lp`, `/api/v2/write`, `/write` to ingester.
- Query ingress routes `/api/v3/query`, `/query`, `/` to querier.
- Flight ingress routes `/arrow.flight.protocol.FlightService` and `/arrow.flight.protocol.sql.FlightSqlService` to querier with gRPC backend protocol.
- Processor ingress routes `/api/v3/engine` to processor when processing engine is enabled.

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

#### Extra Environment Variables

Use top-level `extraEnv` for environment variables that should be applied to every component:

```yaml
extraEnv:
  - name: CUSTOM_VAR
    value: "custom-value"
```

Use component-specific `extraEnv` to target only one component. Component-specific entries override top-level `extraEnv` entries with the same `name`.

```yaml
ingester:
  extraEnv:
    - name: CUSTOM_INGESTER_VAR
      value: "custom-value"
```

Non-processor pods set `INFLUXDB3_UNSET_VARS=INFLUXDB3_PLUGIN_DIR` by default to keep the Processing Engine disabled. If you override `INFLUXDB3_UNSET_VARS`, include `INFLUXDB3_PLUGIN_DIR` yourself or the Processing Engine may initialize on those pods.

When processor pods are enabled, configure `INFLUXDB3_UNSET_VARS` with component-specific overrides for `ingester`, `querier`, and `compactor` instead of top-level `extraEnv`. Component-specific overrides do not apply to processor pods; a top-level `INFLUXDB3_UNSET_VARS` override is also applied to processor pods and can disable the Processing Engine there.

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
  
  # Security: Lock down package management (3.11+)
  disablePackageManagement: false    # Set true to reject package install API calls
  
  # Performance: Control async trigger concurrency (3.11+)
  asyncTriggerConcurrencyLimit: 8    # Limit concurrent async triggers (default: unlimited)
  
  persistence:
    enabled: true
    size: "5Gi"
```

**New in 3.11:**
- `disablePackageManagement`: Reject all package installation requests (security lockdown)
- `asyncTriggerConcurrencyLimit`: Cap concurrent async trigger invocations (prevent runaway usage)

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

1. **Write Path**: Client → Write Ingress → Ingester Service → Ingester Pods → Object Storage
2. **HTTP Query Path**: Client → Query Ingress → Querier Service → Querier Pods → Object Storage
3. **Flight/gRPC Query Path**: Client → Flight Ingress → Querier Service → Querier Pods → Object Storage
4. **Compaction**: Compactor reads from Object Storage, compacts data, writes back
5. **Processing**: Processor nodes execute plugins on data writes, schedules, or HTTP requests

## Upgrading

### Upgrading to 0.9.0 (InfluxDB 3.11.0)

**Chart 0.8.0 → 0.9.0** introduces InfluxDB 3.11.0 with PachaTree storage engine, graceful shutdown, and Processing Engine updates.

**⚠️ IMPORTANT:** This upgrade is **backward compatible**. Existing clusters upgrade seamlessly.

**Quick Upgrade:**
```bash
# Update Helm repository
helm repo update influxdata

# Upgrade to 0.9.0
helm upgrade influxdb3-enterprise influxdata/influxdb3-enterprise \
  --version 0.9.0 \
  --namespace influxdb3 \
  -f my-values.yaml
```

**What happens:**
- Pods restart with new image (3.11.0-enterprise)
- Existing Parquet clusters stay on Parquet (no migration)
- Environment variables use new names (old names log deprecation warnings)
- No data migration required

**For complete upgrade guide including:**
- Breaking changes (environment variable renames, removed options)
- PachaTree migration steps for existing clusters
- New features configuration
- Troubleshooting

**See:** [MIGRATION-3.11.md](./MIGRATION-3.11.md)

### Upgrade the Chart

```bash
helm upgrade influxdb3-enterprise . \
  --namespace influxdb3 \
  -f my-values.yaml
```

### Upgrade from chart 0.6.x

Chart 0.7.0 removes the ingester WAL `volumeClaimTemplates` from the
StatefulSet. Kubernetes does not allow this field to be removed from an existing
StatefulSet during an in-place `helm upgrade`.

For existing releases installed with chart 0.6.x, delete the ingester
StatefulSet before upgrading. This is required for all object-store types
because the immutable `volumeClaimTemplates` field changed.

For `objectStorage.type=file` only, chart 0.6.x stored object-store contents on
the pod's ephemeral filesystem. File storage is intended for development/testing
only. If you used file storage and want to preserve that dev/test data, back up
`objectStorage.file.dataDir` from a live pod before deleting the StatefulSet.

```bash
kubectl delete statefulset -n influxdb3 influxdb3-enterprise-ingester
helm upgrade influxdb3-enterprise . \
  --namespace influxdb3 \
  -f my-values.yaml
```

After the upgraded ingester pods are healthy, delete the old ingester WAL PVCs.
Chart 0.6.x created these PVCs when `ingester.persistence.enabled` was true, but
they were unused leftovers: InfluxDB 3 Enterprise writes the WAL to the
configured object store, not to those local PVC mounts. There is one old WAL PVC
per ingester replica. The PVC name pattern is
`wal-<ingester-statefulset-name>-<ordinal>`, where `<ordinal>` starts at `0`.

```bash
# List old WAL PVCs for the default StatefulSet name and namespace:
kubectl get pvc -n influxdb3 | grep '^wal-influxdb3-enterprise-ingester-'

# Delete one old WAL PVC per old ingester replica:
# wal-influxdb3-enterprise-ingester-0
# wal-influxdb3-enterprise-ingester-1
kubectl delete pvc -n influxdb3 wal-influxdb3-enterprise-ingester-0
kubectl delete pvc -n influxdb3 wal-influxdb3-enterprise-ingester-1
```

Replace `influxdb3-enterprise-ingester` with your old ingester StatefulSet name
and delete one PVC for each old ingester replica ordinal.

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

#### Ingester WAL and Object Storage Issues

WAL files are persisted through the configured object store. Check object
storage connectivity first:
```bash
kubectl logs -n influxdb3 influxdb3-enterprise-ingester-0 | grep -i object
```

View ingester logs for WAL errors:
```bash
kubectl logs -n influxdb3 influxdb3-enterprise-ingester-0 | grep -i wal
```

For `objectStorage.type=file`, also check the shared object-storage PVC:
```bash
kubectl get pvc -n influxdb3 influxdb3-enterprise-object-storage
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
| `image.tag` | Image tag override (defaults to `<appVersion>-enterprise` when empty) | `""` |
| `license.type` | trial, home, or commercial | `trial` |
| `license.email` | Email for trial/home | `""` |
| `license.file` | License file content (use `--set-file license.file=/path/to/file`) | `""` |
| `license.existingSecret` | Secret with `license-email` or `license-file` | `""` |
| `security.auth.adminToken.existingSecret` | Secret with offline admin token key `admin-token.json` | `""` |
| `security.auth.adminToken.file` | Path to offline admin token file; mutually exclusive with `security.auth.adminToken.existingSecret` | `""` |
| `security.auth.permissionTokens.existingSecret` | Secret with offline permission tokens key `permission-tokens.json` | `""` |
| `security.auth.permissionTokens.file` | Path to offline permission tokens file; mutually exclusive with `security.auth.permissionTokens.existingSecret` | `""` |
| `security.auth.adminToken.recovery.httpBind` | Bind address for admin token recovery endpoint (`INFLUXDB3_ADMIN_TOKEN_RECOVERY_HTTP_BIND_ADDR`) | `""` |
| `serviceAccount.automountServiceAccountToken` | Configure automatic mounting of the Kubernetes service account token in component pods and the created ServiceAccount | `not set` |
| `extraEnv` | Extra environment variables applied to all components | `[]` |

### Object Storage Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `objectStorage.type` | Storage type (s3, azure, google, file) | `s3` |
| `objectStorage.bucket` | Bucket/container name | `influxdb3-enterprise-data` |
| `objectStorage.s3.region` | AWS region | `us-east-1` |
| `objectStorage.s3.endpoint` | S3 endpoint (for S3-compatible) | `""` |
| `objectStorage.requestTimeout` | Object store request timeout | `""` (server default `30s`) |
| `objectStorage.tlsAllowInsecure` | Skip object-store TLS cert verification (testing only) | `false` |
| `objectStorage.tlsCa.certPath` | Path to custom CA PEM file for object-store TLS verification | `""` |
| `objectStorage.tlsCa.existingSecret` | Secret containing object-store CA PEM (`ca.crt`) | `""` |
| `objectStorage.s3.accessKeyId` / `secretAccessKey` | S3 credentials | `""` |
| `objectStorage.s3.sessionToken` | Optional session token | `""` |
| `objectStorage.s3.credentialsFile` | Credentials file content (use `--set-file objectStorage.s3.credentialsFile=/path/to/file`) | `""` |
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
| `ingester.extraEnv` | Extra environment variables applied only to ingester pods | `[]` |
| `querier.extraEnv` | Extra environment variables applied only to querier pods | `[]` |
| `compactor.extraEnv` | Extra environment variables applied only to compactor pods | `[]` |
| `processingEngine.extraEnv` | Extra environment variables applied only to Processing Engine pods | `[]` |
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
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.host` | Hostname for all ingresses (set to your domain) | `influxdb.example.com` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.port` | Host port referenced in NOTES | `8181` |
| `ingress.tls` | TLS host/secret list | `[]` |
| `ingress.write.annotations` | Write ingress annotations | `proxy-body-size/read-timeout` |
| `ingress.query.annotations` | Query ingress annotations | `proxy-read-timeout` |
| `ingress.flight.host` | Optional host override for Flight ingress | `""` (uses `ingress.host`) |
| `ingress.flight.tls` | Optional TLS override for Flight ingress. Required when `ingress.flight.host` differs from `ingress.host`. | `[]` |
| `ingress.flight.annotations` | Flight ingress annotations (includes GRPC backend protocol) | includes `backend-protocol: GRPC` |
| `ingress.processor.annotations` | Processor ingress annotations | `{}` |

Ingress routes:
- Write ingress exposes `/api/v3/write_lp`, `/api/v2/write`, `/write`.
- Query ingress exposes `/api/v3/query`, `/query`, `/`.
- Flight ingress exposes `/arrow.flight.protocol.FlightService` and `/arrow.flight.protocol.sql.FlightSqlService`.

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
| `ingester.persistence.enabled` | Deprecated compatibility value; WAL is persisted through the configured object store | `false` |
| `processingEngine.persistence.enabled` | Enable plugins PVC | `true` |
| `objectStorage.type=file` | Creates one shared RWX object-storage PVC mounted at `objectStorage.file.dataDir` | — |
| `objectStorage.file.persistence.accessMode` | Access mode for the file object-storage PVC | `ReadWriteMany` |

### Monitoring Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceMonitor.enabled` | Create ServiceMonitor | `false` |
| `serviceMonitor.namespace` | ServiceMonitor namespace | `""` (release ns) |
| `serviceMonitor.interval` | Scrape interval | `30s` |

See `values.yaml` for complete parameter list.

## License

InfluxDB 3 Enterprise software requires a valid license from InfluxData.
