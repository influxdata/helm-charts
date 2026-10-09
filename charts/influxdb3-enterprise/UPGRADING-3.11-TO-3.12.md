# Upgrade from InfluxDB 3 Enterprise 3.11 to 3.12

Chart 0.16.0 defaults to InfluxDB 3 Enterprise 3.12.0. This chart supports fresh
3.12 installations and upgrades from 3.11.3 or later, including partially
completed 3.11/3.12 rollouts and subsequent 3.12 chart upgrades. Older clusters
must follow their supported upgrade path through chart 0.15.0 first. During a
server-connected upgrade, the chart rejects a release whose ingester StatefulSet
is configured for a recognizable version below 3.11.3. Missing StatefulSets,
custom tags, image digests, and running pod versions cannot be verified, so
verify every node yourself.

Follow the official [upgrade procedure](https://docs.influxdata.com/influxdb3/enterprise/admin/upgrade/)
and review the [3.12 release notes](https://docs.influxdata.com/influxdb3/enterprise/release-notes/#v3120).
Upgrade binaries with the current storage engine. Do not start a storage-engine
migration as part of this operation, or change processor scheduling or enable
distributed compaction at the same time.

## Before upgrading

Verify `influxdb3 --version` on every pod. All source nodes must run 3.11.3 or later;
the reference manual scenario uses 3.11.5. Record all pod images as well as the
release values and current chart version:

```bash
export RELEASE=influxdb3-enterprise
export NAMESPACE=influxdb3
export INFLUXDB3_AUTH_TOKEN="<admin-token>"

helm get values "$RELEASE" -n "$NAMESPACE" -o yaml > pre-3.12-values.yaml
helm get values "$RELEASE" -n "$NAMESPACE" --all -o yaml > pre-3.12-computed-values.yaml
helm list -n "$NAMESPACE" > pre-3.12-releases.txt
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" \
  -o json > pre-3.12-pods.json
```

Take a consistent, restorable backup of everything under the configured catalog
prefix, including `catalog/v3/`. Save the cluster ID, any configured
`engine.pachaTree.enginePathPrefix`, the relevant object-store prefixes, and the
admin credentials valid at backup time. Test restoration in an isolated cluster.
Follow [Back up and restore data](https://docs.influxdata.com/influxdb3/enterprise/admin/backup-restore/)
for the storage engine in use. Preserve the data objects referenced by the saved
catalog too; a catalog copy cannot recreate a deleted data file. Use a full
object-store backup unless catalog-only recovery has been verified for your
engine and workload. Keep the backup outside the live prefixes that cleanup or
restore operations can change.

Remove a retained `image.tag` override or update it to `3.12.0-enterprise`.
`--reuse-values` preserves overrides, so a new chart alone may still run 3.11.
Check the package metadata with:

```bash
helm show chart influxdata/influxdb3-enterprise --version 0.16.0
```

Keep `acknowledgePachaTreeMigration` at its current value. If migration has not
started, leave it false. Setting an acknowledgement is not proof that a backup
exists or any migration has completed.

### Protect the upgraded engine's rollback window

Before the first 3.12 compactor starts, add this entry to the existing
`compactor.extraEnv` list, preserving any other entries:

```yaml
compactor:
  extraEnv:
    - name: INFLUXDB3_COMPACTOR_SWEEP_MODE
      value: "dry-run"
```

The setting belongs to the compactor pod revision; it does not update the shared
ConfigMap read by old pods. Keep it through the rollback window. Once upgrade
verification is complete and the rollback window has closed, remove the override
or change it to the documented normal mode and roll the compactor. Dry-run
prevents sweep deletion, but does not establish that other deletion paths retain
every object needed by a pre-upgrade catalog. Verify recovery before relying on
catalog-only restoration.

## Acknowledge and stage the rollout

Use the official [staged Helm rollout procedure](https://docs.influxdata.com/influxdb3/enterprise/admin/upgrade/#multi-node-upgrade-procedure)
to freeze and release individual StatefulSets. Pin **every** Helm invocation to
chart `0.16.0` and image `3.12.0-enterprise`, and apply the sweep configuration
before releasing the compactor. Upgrade ingesters in order, then queriers, then
the compactor. Process nodes may be upgraded separately, without changing their
scheduling settings. A plain upgrade rolls all enabled modes concurrently.

On the first upgrade, add `--set-string acknowledgeUpgrade=3.12`.
The guard only reads the release's own ConfigMap in its namespace. For 3.12+
or unknown target images, upgrade rendering requires that exact acknowledgement
unless the annotation already records boundary `3.12` or a later boundary.
Known targets below 3.12 do not require the new acknowledgement. Fresh
installations also need none.

The chart emits
`influxdata.com/upgrade-boundary-applied: "3.12"` for identifiable
3.12+ target images. Patch releases retain the same boundary. An existing
higher boundary is preserved, including during frozen or partial rollouts.
Older and unknown targets keep an existing value; unknown tags never create
or advance it, even when acknowledged.

After the initial upgrade records the boundary, later server-connected partition
releases may clear `acknowledgeUpgrade` to `""`, even while some pods
remain on 3.11. An ordinary later 3.12 upgrade can also omit acknowledgement.
Nonempty acknowledgements must be quoted `X.Y` strings. Unquoted YAML
numbers, booleans, patch versions such as `"3.12.0"`, and malformed values are
rejected. When acknowledgement is required, the value must exactly match the
required boundary. A different well-formed boundary is ignored when no
acknowledgement is required, so it approves nothing. A retained `"3.12"`
cannot approve a future boundary.

Client-side previews cannot look up the live marker and still need both
acknowledgements:

```bash
helm template "$RELEASE" influxdata/influxdb3-enterprise \
  --namespace "$NAMESPACE" --version 0.16.0 --is-upgrade \
  -f pre-3.12-values.yaml \
  --set image.tag=3.12.0-enterprise \
  --set-string acknowledgeUpgrade=3.12 \
  --set acknowledgeCatalogMigration=true
```

Prefer `helm upgrade --dry-run=server` when cluster access is available. Plain
`helm template` and template-only GitOps renderers such as Argo CD do not expose
upgrade state and bypass both acknowledgement guards. Before syncing, operators
must verify source versions, take the backup, configure sweep dry-run where
applicable, and plan the staged rollout.

The boundary is determined from the effective image tag, including overrides,
rather than assuming the chart's `appVersion`. The annotation records applied
chart configuration, not running binaries or a completed rollout. It is not
evidence that the server has committed the catalog feature level.

### Writes during mixed-version operation

The official [catalog compatibility guidance](https://docs.influxdata.com/influxdb3/enterprise/admin/upgrade/#catalog-version-compatibility)
states that older nodes cannot modify the catalog during a rolling upgrade across
a catalog version boundary. Writes using existing measurements, tags, and fields
can continue. Route writes that add measurements, tags, or fields to upgraded
ingesters, or wait until all ingesters have been upgraded.

## Verify the upgrade

After each released partition, confirm the expected pod image, binary version,
and readiness. Recreate an old partition-pinned pod after the shared ConfigMap
is updated and confirm it starts correctly before proceeding.

After all modes roll, run `influxdb3 show nodes` from a querier with the admin
token. Check node status by named columns rather than old column positions.
Verify every running node reports 3.12.0, every pod is ready, existing data is
readable, and a new write can be queried. On the upgraded engine, inspect a sweep
pass to confirm candidates are reported without deleting them. Keep
storage-engine migration a separate operation.

## Rollback

The server commits the new catalog feature level once every **running** node is
on 3.12, including the first start of a single-node cluster. An offline 3.11 node
does not postpone commitment. Using none of the new features does not prevent it.
The chart's boundary annotation cannot tell you whether commitment occurred.

Use InfluxDB 3.11.3 or later for any rollback. The
[3.11.3 release notes](https://docs.influxdata.com/influxdb3/enterprise/release-notes/#v3113)
state that it can read the v3 run-set indexes written by later releases.

Before commitment, a binary rollback may remain possible, but confirm the
feature level and the data-format compatibility first. Keep sweep dry-run and
the pre-upgrade backup available throughout this window.

After commitment, Helm rollback alone is insufficient: 3.11 cannot read the live
catalog. Follow the official [catalog recovery requirements](https://docs.influxdata.com/influxdb3/enterprise/admin/upgrade/#before-you-upgrade)
with a coordinated restore:

1. Stop client writes. Scale every StatefulSet in the release to zero, then wait
   until every release StatefulSet pod has been deleted:

   ```bash
   kubectl scale statefulset \
     --namespace "$NAMESPACE" \
     --selector "app.kubernetes.io/instance=$RELEASE" \
     --replicas=0

   kubectl wait --for=delete pod \
     --namespace "$NAMESPACE" \
     --selector "app.kubernetes.io/instance=$RELEASE,controller-revision-hash" \
     --timeout=10m
   ```

   Confirm no StatefulSet workload pods remain before replacing objects.
2. Restore the complete pre-upgrade catalog prefix, removing post-backup catalog
   objects. Restore referenced data objects from the full backup if necessary.
3. Restore the saved values and start the 3.11 workloads with every StatefulSet
   using an unfrozen rolling-update strategy:

   ```bash
   helm upgrade "$RELEASE" influxdata/influxdb3-enterprise \
     --namespace "$NAMESPACE" \
     --version 0.15.0 \
     --reset-values \
     --values pre-3.12-values.yaml \
     --set ingester.updateStrategy.type=RollingUpdate \
     --set ingester.updateStrategy.rollingUpdate.partition=0 \
     --set querier.updateStrategy.type=RollingUpdate \
     --set querier.updateStrategy.rollingUpdate.partition=0 \
     --set compactor.updateStrategy.type=RollingUpdate \
     --set compactor.updateStrategy.rollingUpdate.partition=0 \
     --set processingEngine.updateStrategy.type=RollingUpdate \
     --set processingEngine.updateStrategy.rollingUpdate.partition=0
   ```

   Chart 0.15.0 defaults to `3.11.5-enterprise`. If
   `pre-3.12-values.yaml` sets `image.tag`, verify that it resolves to InfluxDB
   3.11.3 or later before running the command. The explicit strategy overrides
   prevent a retained partition or update strategy from recreating a 3.12 pod.
4. Verify readiness, confirm every node reports InfluxDB 3.11.3 or later, query
   pre-upgrade data, and perform a new write before resuming traffic.

Writes accepted after the backup may be lost. Never leave 3.12 processes writing
to the restored 3.11 catalog.

## Behavior changes

See [cluster processing](https://docs.influxdata.com/influxdb3/enterprise/admin/processing-engine-cluster/)
for trigger ownership and [orphaned file cleanup](https://docs.influxdata.com/influxdb3/enterprise/admin/orphaned-file-cleanup/)
for sweep operation.

Review the official [configuration reference](https://docs.influxdata.com/influxdb3/enterprise/reference/config-options/)
for limits and their tuning options. Use existing chart values or the relevant
component's `extraEnv` instead of assuming every product option has a chart key.

- Query concurrency has a finite default; excess queries queue for a slot.
- On Parquet, WAL buffering limits are enforced. A full buffer returns `429`;
  tune `ingester.wal.maxWriteBufferSize` and client retry behavior if needed.
- On the upgraded engine, the file-cache budget also counts files retained by
  active queries. Budget exhaustion returns HTTP `429` or Flight `RESOURCE_EXHAUSTED`; review
  `caching.fileCacheSize` and per-component overrides.
- Parquet nodes without query mode return `405` for data queries. Route data
  queries to queriers; system-table queries remain available on other modes.
- Trigger ownership follows process-node schedulers. Multiple processors can
  execute a WAL trigger for the same flush, and restart replay can repeat
  execution. To run once per WAL flush, select a single process node in the trigger
  configuration; review plugin idempotency. A saturated
  request-trigger queue returns `503`.
- On the upgraded engine, the primary compactor automatically sweeps orphaned
  files. Retain `INFLUXDB3_COMPACTOR_SWEEP_MODE=dry-run` during the rollback window.
- `compactor.compaction.maxNumFilesPerPlan` remains accepted for saved values,
  but InfluxDB 3.12+ ignores it. The chart prints a non-blocking warning when set.
- `system.nodes` and `system.tables` have changed column positions. Select
  named columns. `pow()` and `power()` now return floats for integer arguments.
- Username/password sessions issued before the upgrade need a refresh or new
  login. API tokens are unaffected.

### Metrics

Review monitoring against the official [3.12 release notes](https://docs.influxdata.com/influxdb3/enterprise/release-notes/#v3120).
`http_requests*` counts HTTP and `grpc_requests*` counts gRPC;
`path` and `method_path` use route templates rather than literal request paths.
Update filters and aggregation accordingly. On Parquet,
`influxdb3_compaction_plans_skipped` now uses `reason="memory_exhaustion"`
and drops `phase`. These memory-pool metrics are removed:

- `influxdb3_memory_pool_evictions`
- `influxdb3_memory_pool_rejections`
- `influxdb3_memory_pool_eviction_bytes`
- `influxdb3_memory_pool_eviction_size_bytes`
- `influxdb3_memory_pool_eviction_duration_seconds`
