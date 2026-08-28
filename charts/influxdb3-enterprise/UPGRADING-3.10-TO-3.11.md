# Upgrade from InfluxDB 3 Enterprise 3.10 to 3.11

Chart 0.10.0 upgrades InfluxDB 3 Enterprise from 3.10.5 to 3.11.2. Upgrade the
binary first with the existing Parquet storage engine, verify the cluster, and
then decide separately whether to migrate to PachaTree.

Do not enable PachaTree migration during the initial 3.11 rollout. InfluxDB
rejects the combined operation with:

```text
The Parquet compactor node must be run before initiating PachaTree upgrade
```

See the official [upgrade](https://docs.influxdata.com/influxdb3/enterprise/admin/upgrade/),
[storage engine](https://docs.influxdata.com/influxdb3/enterprise/reference/internals/storage-engine/),
and [release](https://docs.influxdata.com/influxdb3/enterprise/release-notes/)
documentation.

## Before upgrading

Back up the cluster's object storage and verify that the backup can be restored.
If your values set `image.tag`, remove the override or change it to
`3.11.2-enterprise`; otherwise Helm continues deploying the overridden image.

If `http.maxRequestSize` is set, keep it as a bare byte count, for example
`10485760`, until every pod runs InfluxDB 3.11.2. InfluxDB 3.10.5 rejects
unit-suffixed values such as `10mb`.

Save the current release values:

```bash
export RELEASE=influxdb3-enterprise
export NAMESPACE=influxdb3
export VALUES_FILE=./my-values.yaml
export INFLUXDB3_AUTH_TOKEN="<admin-token>"

helm get values "$RELEASE" -n "$NAMESPACE" -o yaml > pre-3.11-values.yaml
```

Keep the migration acknowledgement disabled for the initial version upgrade:

```yaml
acknowledgePachaTreeMigration: false
```

## Upgrade to chart 0.10.0

For a multi-node deployment, follow the official
[staged Helm rollout procedure](https://docs.influxdata.com/influxdb3/enterprise/admin/upgrade/#multi-node-upgrade-procedure)
using chart version `0.10.0`.

Chart 0.10.0 emits both preferred 3.11 environment-variable names and their
pre-3.11 aliases for settings supported by earlier chart versions. This keeps
pods pinned to 3.10 correctly configured if they restart during the staged
rollout. InfluxDB 3.11 uses the preferred names and logs deprecation warnings
for the aliases.

After all StatefulSets finish rolling, verify the nodes from a querier pod:

```bash
QUERIER_POD=$(kubectl get pods -n "$NAMESPACE" \
  -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=querier" \
  -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n "$NAMESPACE" "$QUERIER_POD" -- \
  influxdb3 show nodes \
  --host http://127.0.0.1:8181 \
  --token "$INFLUXDB3_AUTH_TOKEN"
```

Verify that every node reports `running`, every pod is ready, and every pod runs
InfluxDB 3.11.2. Query existing data and test a new write before starting the
storage engine migration.

### Upgrade directly from chart 0.8.x

Chart 0.8.x runs InfluxDB 3.9 and must also perform the one-way catalog v2 to
v3 migration introduced in 3.10. Follow the backup precautions in
[UPGRADING-3.9-TO-3.10.md](UPGRADING-3.9-TO-3.10.md) and add
`--set acknowledgeCatalogMigration=true` to the version upgrade. Keep
`acknowledgePachaTreeMigration=false` until the catalog migration and the
3.11.2 deployment have both been verified.

Catalog migration and PachaTree migration are separate operator decisions and
use separate acknowledgements.

## Migrate an existing cluster to PachaTree

`acknowledgePachaTreeMigration` is for clusters created by InfluxDB 3.10 or
earlier, which remain on the Parquet engine until the migration is explicitly
enabled. New clusters created by InfluxDB 3.11 use PachaTree automatically and
do not need this acknowledgement.

The migration is one-way for normal chart operation. It consumes additional
CPU and memory while existing Parquet files are converted, and data written in
the new format cannot be read by older InfluxDB versions. Test the procedure in
a non-production environment and take a fresh backup before continuing.

Start the migration with a separate acknowledged upgrade:

```bash
helm upgrade "$RELEASE" influxdata/influxdb3-enterprise \
  -n "$NAMESPACE" \
  --version 0.10.0 \
  --reuse-values \
  --set acknowledgePachaTreeMigration=true \
  --wait --timeout 30m
```

The chart sets `INFLUXDB3_UPGRADE_PACHA_TREE=true` for every enabled component.
Query the system tables and wait until every node reports `completed`:

```sql
SELECT * FROM system.upgrade_parquet_node;
SELECT * FROM system.upgrade_parquet;
```

The acknowledgement may remain enabled after completion. InfluxDB resolves the
storage engine from the
[mode persisted in the catalog](https://docs.influxdata.com/influxdb3/enterprise/release-notes/),
so an upgraded catalog continues using the upgraded engine on subsequent
starts.

Do not use Helm rollback to return to an older InfluxDB version after PachaTree
data has been written. This chart does not automate cleanup or downgrade back
to the Parquet engine.

## Renamed and retained values

Chart 0.10.0 emits the preferred InfluxDB 3.11 environment-variable names while
retaining existing Helm value keys.

- `memory.execMemPoolSize` replaces `memory.execMemPoolBytes`.
- `memory.forceSnapshotMemSize` replaces
  `memory.forceSnapshotMemThreshold`.
- `caching.fileCacheSize` replaces `caching.parquetMemCacheSize`.
- `cluster.waitForRunningIngester` replaces the misspelled
  `cluster.waitForRunningIngestor`.

When both a preferred and legacy size or ingester-wait key are present, the
preferred key wins. Legacy size keys continue using the deprecated 3.11 aliases
so bare numbers retain their pre-3.11 MiB meaning; percentages and unit-suffixed
values also remain supported. Preferred size keys must use an explicit unit or
percentage accepted by InfluxDB 3.11.

`objectStorage.cacheEndpoint` is deprecated and has no effect with InfluxDB
3.11+. The chart retains it for values compatibility and prints a non-blocking
Helm note when it is set. Remove it before a future chart release.

`dataLifecycle.hardDeleteDefaultDuration` remains accepted. InfluxDB 3.11.2
logs that it is deprecated and has no effect.

InfluxDB 3.11 removes the Prometheus `db` label from metrics. Review dashboards
and alerts that select or group by this label; see the official
[release notes](https://docs.influxdata.com/influxdb3/enterprise/release-notes/).
