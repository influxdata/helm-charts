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

## Processing Engine

The InfluxDB 3 Core image enables the Processing Engine with
`INFLUXDB3_PLUGIN_DIR=/plugins`. Enable persistent storage for that directory
when plugins must survive pod replacement:

```yaml
processingEngine:
  pluginDir: /plugins
  persistence:
    enabled: true
    storageClass: ""
    size: 5Gi
    accessMode: ReadWriteOnce
```

By default, plugin storage is ephemeral unless `extraVolumeMounts` provides
storage at `pluginDir`.

Optional settings include `processingEngine.pluginRepo`,
`processingEngine.virtualEnvLocation`, and `processingEngine.packageManager`.

## Configuration

Values under `wal`, `logs`, `telemetry`, `datafusion`, `memory`, `caching`, and
`dataLifecycle` map to the documented InfluxDB 3 Core environment variables.
Use `extraEnv`, `extraVolumes`, and `extraVolumeMounts` for options not exposed
directly by the chart.

StatefulSet updates use `RollingUpdate` by default. Set
`updateStrategy.type=OnDelete` when pod replacement must be controlled
manually. Core remains a single-replica deployment with either strategy.

## Upgrading

```sh
helm repo update
helm upgrade core influxdata/influxdb3-core -f my-values.yaml
```

The single Core pod is unavailable while it restarts.

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
| `objectStorage.type` | `file`, `memory`, `memory-throttled`, `s3`, `google`, or `azure` | `s3` |
| `objectStorage.file.persistence.size` | Local file-store PVC size | `100Gi` |
| `security.auth.disabled` | Start without authentication | `false` |
| `security.auth.disableAuthz` | Endpoints that bypass authorization | `[health]` |
| `security.tls.enabled` | Enable backend TLS | `false` |
| `processingEngine.persistence.enabled` | Create a plugin PVC | `false` |
| `processingEngine.persistence.size` | Plugin PVC size | `5Gi` |
| `ingress.enabled` | Create HTTP and Flight ingresses | `false` |
| `serviceMonitor.enabled` | Create a Prometheus Operator ServiceMonitor | `false` |
| `updateStrategy.type` | StatefulSet update strategy | `RollingUpdate` |

See `values.yaml` for the complete parameter list.

See the official documentation:

- [Install InfluxDB 3 Core](https://docs.influxdata.com/influxdb3/core/install/)
- [Core configuration options](https://docs.influxdata.com/influxdb3/core/reference/config-options/)
- [Configure object storage](https://docs.influxdata.com/influxdb3/core/admin/object-storage/)
- [Use a preconfigured admin token](https://docs.influxdata.com/influxdb3/core/admin/tokens/admin/preconfigured/)
- [Apache Arrow Flight clients](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/flight/)
