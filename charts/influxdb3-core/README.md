# InfluxDB 3 Core Helm Chart

This chart deploys one InfluxDB 3 Core node as a Kubernetes StatefulSet.
InfluxDB 3 Core is single-node; use InfluxDB 3 Enterprise when you need high
availability or read replicas.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- A PersistentVolume provisioner when using the `file` object store
- An ingress controller when ingress is enabled
- Prometheus Operator when `serviceMonitor.enabled=true`

## Installation

Add the InfluxData Helm repository:

```sh
helm repo add influxdata https://helm.influxdata.com/
helm repo update
```

Install after configuring an S3 bucket and credentials:

```sh
helm install core influxdata/influxdb3-core -f my-values.yaml
```

S3 is the default and recommended object store for production. Azure Blob
Storage, Google Cloud Storage, and S3-compatible storage are also supported.
The `file` object store is intended for development and testing.

```sh
helm install core ./charts/influxdb3-core \
  --set objectStorage.type=file \
  --set objectStorage.file.persistence.size=100Gi \
  --set objectStorage.file.persistence.storageClass=standard
```

## Access with port-forwarding

```sh
kubectl port-forward svc/core-influxdb3-core 8181:8181
export INFLUXDB3_HOST_URL=http://localhost:8181
```

Create the first admin token:

```sh
kubectl exec -it core-influxdb3-core-0 -- influxdb3 create token --admin
```

## Remote object storage

For `s3`, `google`, and `azure`, the chart does not create a data PVC. InfluxDB
stores its Parquet, catalog, and WAL files in the configured object store.
Credentials, TLS certificates, and admin token files may still use Kubernetes
Secrets and volumes.

### S3 or MinIO

Create a Secret containing `access-key-id` and `secret-access-key`:

```sh
kubectl create secret generic influxdb3-s3 \
  --from-literal=access-key-id=ACCESS_KEY \
  --from-literal=secret-access-key=SECRET_KEY
```

```yaml
objectStorage:
  type: s3
  bucket: influxdb3
  s3:
    region: us-east-1
    endpoint: http://minio.minio.svc.cluster.local:9000
    allowHttp: true
    existingSecret: influxdb3-s3
```

## Authentication

Authentication is enabled by default. To bootstrap an offline admin token,
generate the token file before installation:

```sh
influxdb3 create token --admin \
  --name bootstrap-admin \
  --expiry 365d \
  --offline \
  --output-file admin-token.json
```

Restrict access to the file, then create a Secret:

```sh
chmod 600 admin-token.json
kubectl create secret generic influxdb3-admin-token \
  --from-file=admin-token.json=./admin-token.json
```

```yaml
security:
  auth:
    adminToken:
      existingSecret: influxdb3-admin-token
```

Alternatively, set `security.auth.adminToken.file` when another mechanism
mounts the token file. The chart intentionally does not accept a raw admin
token value.

The Secret volume uses Kubernetes' default file mode, `0644`. The non-root
process can read the token, but the default `fsGroup: 1500` does not remove
world-read access. The server's strict `0600` permission warning remains.

## TLS

Use an existing TLS Secret:

```yaml
security:
  tls:
    enabled: true
    existingSecret: influxdb3-tls
```

The Secret must contain `tls.crt` and `tls.key`.

## Ingress

HTTP and Flight/gRPC use separate Ingress resources so gRPC-specific
annotations do not affect HTTP routes:

```yaml
ingress:
  enabled: true
  host: influxdb.example.com
  className: nginx
  http:
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: 100m
  flight:
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: GRPC
```

Flight SQL requires an ingress controller configured for HTTP/2. Set
`ingress.flight.host` to use a separate Flight hostname.

The default shared-host configuration targets ingress-nginx. Other ingress
controllers may not merge separate HTTP and gRPC Ingress resources for the same
host. Use `ingress.flight.host` or controller-specific routing configuration
when required.

## Monitoring

Set `serviceMonitor.enabled=true` to create a Prometheus Operator
`ServiceMonitor` for `/metrics`. When authentication is enabled, also add
`metrics` to `security.auth.disableAuthz`:

```yaml
security:
  auth:
    disableAuthz:
      - health
      - metrics

serviceMonitor:
  enabled: true
```

The chart rejects an authenticated ServiceMonitor configuration that leaves
`/metrics` protected because the generated ServiceMonitor has no token.

When backend TLS is enabled, the ServiceMonitor uses HTTPS. Configure
`serviceMonitor.tlsConfig` if Prometheus needs custom TLS settings.

Review the [upgrade metrics guidance](UPGRADING-3.10-TO-3.12.md#review-the-behavior-changes).
The upgrade changes metric labels and splits HTTP and gRPC request counters.

## Processing Engine

The InfluxDB 3 Core image enables the Processing Engine with
`INFLUXDB3_PLUGIN_DIR=/plugins`. Enable persistent storage for that directory
when plugins and installed packages must survive pod replacement:

```yaml
processingEngine:
  pluginDir: /plugins
  persistence:
    enabled: true
    storageClass: ""
    size: 5Gi
    accessMode: ReadWriteOnce
```

By default, plugin files and installed packages are ephemeral unless
`extraVolumeMounts` provides storage at `pluginDir`.

Optional settings include `processingEngine.pluginRepo`,
`processingEngine.virtualEnvLocation`, and `processingEngine.packageManager`.

InfluxDB 3.11+ also supports:

- `processingEngine.disablePackageManagement`: prevents Python environment
  changes and package installation, taking precedence over `packageManager`.
- `processingEngine.asyncTriggerConcurrencyLimit`: limits concurrent async
  trigger invocations; leaving it unset keeps the server's unlimited default.

To reuse a plugins PVC, set `processingEngine.persistence.enabled=true` and
`processingEngine.persistence.existingClaim` to its name. The PVC must exist in
the release namespace; `storageClass`, `size`, and `accessMode` are then ignored.
The chart does not copy existing plugin data. Changing an existing StatefulSet's
claim templates may require recreating the StatefulSet while retaining its PVCs.

Install Python package dependencies after the pod is running:

```sh
kubectl exec -it POD_NAME -- \
  influxdb3 install package \
    --plugin-dir /plugins \
    --token AUTH_TOKEN \
    pandas
```

Replace `POD_NAME` with the InfluxDB pod name and `AUTH_TOKEN` with an admin
token. Omit `--token AUTH_TOKEN` when authentication is disabled.

For programmatic installation or CI/CD workflows, use the
[package installation HTTP API](https://docs.influxdata.com/influxdb3/core/plugins/#manage-plugin-dependencies).
The chart does not install packages automatically.

## Configuration

`nodeId` defaults to `$(POD_NAME)`. When reusing data from an existing Core
deployment, set it to that deployment's original node ID:

```yaml
nodeId: "existing-node"
```

The node ID determines which stored data the server loads. Keep it unchanged
when reusing that data.

Values under `wal`, `logs`, `telemetry`, `datafusion`, `memory`, `caching`, and
`dataLifecycle` map to the documented InfluxDB 3 Core environment variables.
Use `extraEnv`, `extraVolumes`, and `extraVolumeMounts` for options not exposed
directly by the chart.

The newer `memory.execMemPoolSize`, `memory.forceSnapshotMemSize`, and
`caching.fileCacheSize` settings require units such as `1gb` or a whole percentage
such as `20%`. Kubernetes units such as `Gi` are not server size units. The
existing aliases `execMemPoolBytes`, `forceSnapshotMemThreshold`, and
`parquetMemCacheSize` remain supported with their original parsing, where bare
numbers mean MB. If both Helm keys are set, the newer key takes precedence.

Shared configuration emits compatible old and new environment variable names
where necessary for 3.10.5 and 3.12.3. Legacy bare sizes stay under the legacy name
so they are not reinterpreted by the new parser. `image.tag` overrides remain
effective, including when carried over with `--reuse-values`.

`objectStorage.cacheEndpoint` is ignored in 3.11+. The
`dataLifecycle.hardDeleteDefaultDuration` option has never affected server
behavior; newer binaries warn when it is set. Both keys remain accepted for
existing values files, but remove them from new configurations.

Use `shutdown.timeout` for the connection-drain timeout and
`shutdown.terminationGracePeriodSeconds` for Kubernetes' termination grace
period. Leave time beyond the drain for background work and WAL shutdown; for
example, use `60s` and `90`, respectively. Unset values keep the server and
Kubernetes defaults. The chart rejects an explicitly configured grace period
that cannot outlast the configured drain.

StatefulSet updates use `RollingUpdate` by default. Set
`updateStrategy.type=OnDelete` when pod replacement must be controlled
manually. Core remains a single-replica deployment with either strategy.

## Upgrading

Chart 0.2.0 targets InfluxDB 3 Core 3.12.3. Before upgrading from chart 0.1.1
(Core 3.10.5), follow [UPGRADING-3.10-TO-3.12.md](UPGRADING-3.10-TO-3.12.md).
This direct upgrade includes the 3.11 configuration changes and the one-way
3.12 catalog change. Back up `{prefix}/catalog/` before the first 3.12 start.

```sh
helm repo update
helm upgrade core influxdata/influxdb3-core -f my-values.yaml --set-string acknowledgeUpgrade=3.12
```

The single Core pod is unavailable while it restarts. The acknowledgement is
required once per existing release crossing the 3.12 boundary. Fresh installs
do not require it. The marker records chart configuration history, not backup
or catalog-migration completion.

## Extra Objects

Use `extraObjects` (default `[]`) to add Kubernetes resources to the release.
Entries can be YAML objects or strings; both support Helm templating.

```yaml
extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: "{{ .Release.Name }}-custom"
      namespace: "{{ .Release.Namespace }}"
    data:
      release: "{{ .Release.Name }}"
```

Load a file with `--set-file`:

```sh
helm upgrade --install core . -f my-values.yaml --set-file 'extraObjects[0]=extra-manifest.yaml'
```

- `--set-file` updates the indexed entry in the values assembled for that
  command, but Helm does not merge that resulting list with `extraObjects`
  stored by the previous release. When adding an entry, include all existing
  entries in the values files passed to the same upgrade, then use an unused
  index. Do not rely on `--reuse-values` to preserve omitted entries.
- Object-form substitutions can break YAML or silently change values. For
  arbitrary text, use string entries/files and apply `quote` to the complete
  field value.
- To adopt a resource not managed by Helm, keep its API group/kind/name/namespace
  and use `--take-ownership` (Helm 3.17+). Cross-release transfers need a separate
  migration: the original release can still delete resources on upgrade/uninstall.

## Uninstallation

```sh
helm uninstall core
```

For the `file` object store, Helm does not delete the StatefulSet PVC. Delete it
only when its data is no longer needed:

```sh
kubectl delete pvc -l app.kubernetes.io/instance=core
```

Remote object-store data is not deleted by uninstalling the chart.

## Key parameters

| Parameter | Description | Default |
| --- | --- | --- |
| `image.tag` | Image tag override | `""` (`<appVersion>-core`) |
| `nodeId` | InfluxDB node ID; preserve it when reusing existing data | `$(POD_NAME)` |
| `acknowledgeUpgrade` | One-time acknowledgement of the 3.12 upgrade boundary | `""` |
| `objectStorage.type` | `file`, `memory`, `memory-throttled`, `s3`, `google`, or `azure` | `s3` |
| `objectStorage.file.persistence.size` | Local file-store PVC size | `100Gi` |
| `security.auth.disabled` | Start without authentication | `false` |
| `security.auth.disableAuthz` | Endpoints that bypass authorization | `[health]` |
| `security.tls.enabled` | Enable backend TLS | `false` |
| `processingEngine.persistence.enabled` | Create a plugin PVC | `false` |
| `processingEngine.persistence.size` | Plugin PVC size | `5Gi` |
| `processingEngine.persistence.existingClaim` | Existing plugins PVC in the release namespace | `""` |
| `processingEngine.disablePackageManagement` | Prevent Python environment changes and package installation (3.11+) | unset |
| `processingEngine.asyncTriggerConcurrencyLimit` | Concurrent async trigger invocations (3.11+) | unset |
| `shutdown.timeout` | Connection-drain timeout | server default |
| `shutdown.terminationGracePeriodSeconds` | Pod termination grace period | Kubernetes default |
| `ingress.enabled` | Create HTTP and Flight ingresses | `false` |
| `serviceMonitor.enabled` | Create a Prometheus Operator ServiceMonitor | `false` |
| `serviceMonitor.tlsConfig` | Prometheus Operator TLS settings for metrics scraping | `{}` |
| `serviceAccount.automountServiceAccountToken` | Configure automatic mounting of the Kubernetes service account token in the pod and the created ServiceAccount | `not set` |
| `updateStrategy.type` | StatefulSet update strategy | `RollingUpdate` |

See `values.yaml` for the complete parameter list.

See the official documentation:

- [Install InfluxDB 3 Core](https://docs.influxdata.com/influxdb3/core/install/)
- [Core configuration options](https://docs.influxdata.com/influxdb3/core/reference/config-options/)
- [Configure object storage](https://docs.influxdata.com/influxdb3/core/admin/object-storage/)
- [Use a preconfigured admin token](https://docs.influxdata.com/influxdb3/core/admin/tokens/admin/preconfigured/)
- [Apache Arrow Flight clients](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/flight/)
