# InfluxDB 3 Enterprise manual test design

## Purpose

Provide tracked, repeatable manual scenarios for lifecycle behavior that the
current fresh-install CI cannot validate.

## Structure

Manual scenarios live under:

    charts/influxdb3-enterprise/tests/manual/

Reusable support and diagnostic tools live separately under:

    charts/influxdb3-enterprise/tools/

`ci/` remains reserved for chart-testing values. `templates/tests/` remains
reserved for Helm test-hook resources.

## Dispatch

`tests/manual/run.sh` dynamically resolves a safe scenario name to an executable
under `tests/manual/scenarios/`. It contains no scenario registry. Adding a
scenario does not require changing the runner.

Initial scenarios:

- `fresh-install`
- `upgrade-3.10-to-3.11`
- `migrate-parquet-to-pacha-tree-3.11`

## Environment

The scripts require Bash 3.2, Helm, kubectl, curl, an existing Kubernetes
cluster, an S3-compatible object store, and a license secret. They do not create
or manage those prerequisites.

Each invocation runs one scenario using an explicitly supplied namespace,
values file, and Kubernetes context. Authentication is disabled for the initial
upgrade scenarios. The topology contains one ingester, querier, compactor, and
processor.

## Isolation

Each run generates a unique Helm release name and InfluxDB `cluster.id`.
Contributors may reuse a namespace, license secret, and S3 bucket without
reusing database state. Historical source charts come from the published Helm
repository; the target is the local chart.

The 3.10-to-3.11 scenario installs chart 0.9.2 / InfluxDB 3.10.5 and upgrades
the same release to local chart 0.10.0 / InfluxDB 3.11.2 using `--reuse-values`.

Historical 3.9-to-3.10 automation is not backfilled. Chart 0.8 users follow the
staged 0.8.0 -> 0.9.2 -> 0.10.0 path.

## Verification

Scenarios wait for every enabled role, seed uniquely identifiable data, save
the raw query result, capture pre-change state, perform the lifecycle change,
verify old and new data, and capture post-change state.

Processor coverage is limited to readiness and effective configuration.
Executing plugins belongs in a separate future scenario.

## PachaTree migration

The migration scenario first establishes a 3.11.2 Parquet cluster, then performs
a separate Helm upgrade using the PachaTree-specific one-time acknowledgement.
It verifies migration state and data preservation.

## Safety and cleanup

Mutating scenarios require `--yes`. They never delete S3 data. Successful runs
uninstall their generated Helm release unless `--keep` is supplied. Failed runs
remain deployed for inspection.

Scenarios own cleanup for every resource or background process they start.
Artifacts never contain secret or token values.

## Automation boundary

Upgrade scenarios do not run in CI. A future CI check may validate shell syntax,
but real scenarios remain explicit contributor actions.
