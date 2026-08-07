# Upgrade from InfluxDB 3 Enterprise 3.9 to 3.10

InfluxDB 3.10 automatically, idempotently, and crash-safely migrates catalog
v2 to v3 on first startup. The migration is one-way: InfluxDB 3.9 cannot read
the migrated catalog. Returning to 3.9 requires restoring a pre-upgrade catalog
backup.

See the official [upgrade](https://docs.influxdata.com/influxdb3/enterprise/admin/upgrade/),
[backup](https://docs.influxdata.com/influxdb3/enterprise/admin/backup-restore/),
and [release](https://docs.influxdata.com/influxdb3/enterprise/release-notes/)
documentation.

## Before upgrading

```bash
export RELEASE=influxdb3-enterprise
export NAMESPACE=influxdb3
export VALUES_FILE=./my-values.yaml
export TARGET_CHART_VERSION=0.9.0

helm get values "$RELEASE" -n "$NAMESPACE" -o yaml > pre-3.10-values.yaml
kubectl get pods -n "$NAMESPACE" \
  -l "app.kubernetes.io/instance=$RELEASE" \
  -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image,READY:.status.containerStatuses[0].ready
```

Quiesce writes. Back up `{prefix}/catalog/v2/logs/` and
`{prefix}/catalog/v2/snapshot` in object storage, and verify that the backup can
be restored.

If `VALUES_FILE` sets `image.tag`, remove the override or change it to
`3.10.5-enterprise`. Otherwise, the chart continues deploying the overridden
image.

## Upgrade

The chart does not enforce the documented ingester, querier, compactor upgrade
order, so use a maintenance window.

After completing the backup, persist the acknowledgement in your values file:

```yaml
acknowledgeCatalogMigration: true
```

```bash
helm repo update
helm upgrade "$RELEASE" influxdata/influxdb3-enterprise \
  -n "$NAMESPACE" \
  --version "$TARGET_CHART_VERSION" \
  -f "$VALUES_FILE" \
  --wait --timeout 30m
```

Do not use `--atomic`, and do not run `helm rollback` to a 3.9 revision after
the catalog migration. Both can restore a 3.9 image while leaving the catalog
at v3. To return to 3.9, first restore the pre-upgrade catalog backup. Do not
enable `INFLUXDB3_UPGRADE_PACHA_TREE`; migrate the storage engine separately.

## Verify

```bash
kubectl get pods -n "$NAMESPACE" \
  -l "app.kubernetes.io/instance=$RELEASE" \
  -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image,READY:.status.containerStatuses[0].ready
```

Confirm that every pod runs 3.10.5, then query existing data and test a new
write. Do not downgrade without restoring the pre-upgrade catalog backup.

## Existing 3.10 image override

If the release already runs 3.10 through `image.tag`, its catalog is already
migrated. Back up the catalog, remove or update the override, and still pass
`acknowledgeCatalogMigration: true` in the values file; the chart cannot
determine which image version was previously deployed.
