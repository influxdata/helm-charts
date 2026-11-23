# Upgrade InfluxDB 3 Core from 3.10.5 to 3.12.3

Chart 0.1.1 runs Core 3.10.5 by default; chart 0.2.0 runs Core 3.12.3.
This guide covers the direct upgrade and the intervening 3.11 configuration
changes. Core remains a single-node deployment.

## Before the first 3.12 startup

InfluxDB 3.12 commits a new catalog feature level on first startup of the single
Core node. Back up everything under the instance's `{prefix}/catalog/`,
including the catalog snapshot and logs under `catalog/v3/`, before that start.
Keep the backup and the previous chart, image tag, and values until you no longer
need rollback.

Stop Core while taking a consistent backup. Resolve the actual object-store
prefix from the deployment; `{prefix}` is a placeholder, not a literal directory.
Store the backup separately from the live catalog. For `file` storage, retaining
the PVC alone is not a pre-upgrade backup because the new process updates that
same data.

Core 3.12.0 failed to load some catalogs originally written by Core before 3.10.
The duplicate automatic field-family issue was fixed in 3.12.1 and is included in
the 3.12.3 target. Do not edit the catalog manually.

## Review the 3.11 configuration changes

Existing Helm value keys remain supported. The chart preserves compatible
legacy environment names for a 3.10.5 image carried over through `image.tag` or
an older pod revision reading the updated ConfigMap.

- Prefer `memory.execMemPoolSize`, `memory.forceSnapshotMemSize`, and
  `caching.fileCacheSize` for new configuration. Specify a whole percentage
  (`20%`) or an explicit server unit (`1gb`). `b`, `kb`, `mb`, `gb`, and `tb` are
  1024-based; Kubernetes quantity suffixes such as `Gi` are invalid here.
- The legacy Helm keys `execMemPoolBytes`, `forceSnapshotMemThreshold`, and
  `parquetMemCacheSize` retain their original parser: a bare number means MB.
  A new key takes precedence if both Helm keys are supplied.
- `http.maxRequestSize` keeps bare numbers as bytes; a unit such as `10mb` is
  accepted by 3.12.3. Keep a bare byte count if an older image still needs the
  same shared configuration.
- `objectStorage.cacheEndpoint` never configured a functional cache. Since 3.11
  its environment variable is ignored and the old command flag is rejected.
- `dataLifecycle.hardDeleteDefaultDuration` has never affected server behavior.
  The server now warns when it is supplied; remove it from your values.
- Python package-management disabling and asynchronous-trigger concurrency
  limits are available through the new processing-engine keys on 3.11+.
- Startup probes now allow about 15 minutes for catalog loading and WAL replay.
  If you set a drain timeout, also give Kubernetes enough termination grace.

## Review the behavior changes

- The chart now correctly applies
  `security.auth.adminToken.recovery.httpBind`. A non-empty value enables the
  unauthenticated admin-token recovery listener at that address; earlier chart
  versions ignored it. Remove the setting if recovery should remain disabled.
- In 3.11, several write/compaction metrics lose the `db` label. Review dashboards
  that filter or group by it; a per-database series is not recreated by removing
  a filter from the query.
- In 3.12, query concurrency has a finite default: the larger of 50 and four
  times the node's query parallelism. Queries over the limit wait for a slot.
- `wal.maxWriteBufferSize` now bounds pending write requests. The default server
  limit is 100000; a full buffer returns `429 Too Many Requests` until it drains.
  Review write-client retry behavior and tune the existing setting if needed.
- HTTP and gRPC request metrics are split by protocol, and request-path labels
  use route templates. Review dashboards and alerts that aggregate both metric
  families or filter on literal paths.

## Upgrade the chart

Confirm that your catalog backup is complete, review your values, and make sure
an explicit `image.tag` does not retain 3.10.5 unintentionally.

```sh
helm upgrade core influxdata/influxdb3-core --version 0.2.0 -f my-values.yaml --set-string acknowledgeUpgrade=3.12
```

`acknowledgeUpgrade: "3.12"` confirms operator intent. It does not take a backup
or prove that migration has completed. Fresh installs require no acknowledgement.
A fresh Helm release that reuses old data still needs the pre-upgrade backup.
Subsequent Helm upgrades use the ConfigMap's recorded boundary. A recognized
3.10.5 image override does not claim to have applied 3.12.

Custom image tags cannot be inferred from the chart version: an unknown target
requires explicit acknowledgement on upgrade, and the chart does not invent a
3.12 marker for it. Use `helm upgrade --dry-run=server` to exercise the checks
against live release metadata. Client-side upgrade previews need the explicit
acknowledgement when they cannot read the marker. Template-only GitOps renderers
must enforce this operational step outside Helm.

Verify that the Core pod starts, its actual image is 3.12.3, and existing data,
writes, queries, authentication, and any configured plugins still work.

## Roll back to the previous chart and Core 3.10.5

1. Stop the 3.12 process before restoring data.
2. Restore the complete pre-upgrade `{prefix}/catalog/` backup to its original
   location. Do not merge new catalog logs into the restored backup.
3. Reinstall the previous chart version and original image and values, then
   start Core 3.10.5 and verify the data.

A plain Helm rollback changes Kubernetes resources but does not restore the
catalog. This procedure does not assume how a 3.10.5 binary would handle a
catalog modified by 3.12. Writes accepted after the backup may be lost on
rollback.

## References

- [Core upgrade guide](https://docs.influxdata.com/influxdb3/core/admin/upgrade/)
- [Core release notes](https://docs.influxdata.com/influxdb3/core/release-notes/)
- [Core configuration and 3.11 renames](https://docs.influxdata.com/influxdb3/core/reference/config-options/)
