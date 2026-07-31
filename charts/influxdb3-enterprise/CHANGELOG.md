# Changelog

All notable changes to the InfluxDB 3 Enterprise Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.0] - 2026-07-31

### Added

#### PachaTree Storage Engine Support
- Added `engine.upgradePachaTree` flag to enable Parquet → PachaTree migration for existing clusters
- Added `engine.pachaTree` configuration section with tuning options:
  - `shardCount`: Number of shards (default: 1)
  - `maxTotalColumns`: Maximum columns across all tables (default: 5000)
  - `snapshotSize`: Snapshot size threshold (default: 100000)
  - `gen0MaxFileSize`: Maximum Gen0 file size (default: "100mb")
  - `walReplicaQueueLength`: WAL replica queue length (default: 1000)
- Added `--upgrade-pacha-tree` arg to all StatefulSets when migration flag is set
- Created `influxdb3-enterprise.pachaTreeEnv` helper template for PachaTree environment variables
- New clusters automatically use PachaTree storage engine (no configuration required)

#### Graceful Shutdown Support
- Added `shutdown.timeout` configuration for connection drain timeout (default: "30s")
- Added `INFLUXDB3_SHUTDOWN_TIMEOUT` environment variable to ConfigMap
- Improves rolling update experience by draining connections before pod shutdown

#### Processing Engine Updates
- Added `processingEngine.disablePackageManagement` flag to lock down package installations
- Added `processingEngine.asyncTriggerConcurrencyLimit` to control concurrent async trigger invocations
- Added `INFLUXDB3_DISABLE_PACKAGE_MANAGEMENT` environment variable to processor StatefulSet
- Added `INFLUXDB3_ASYNC_TRIGGER_CONCURRENCY_LIMIT` environment variable to processor StatefulSet

#### Documentation
- Added `MIGRATION-3.11.md` with comprehensive upgrade guide covering:
  - Breaking changes summary
  - Step-by-step upgrade scenarios (fresh install, existing cluster, PachaTree migration)
  - Post-upgrade validation procedures
  - Rollback procedures
  - Troubleshooting guide
- Updated README.md with:
  - "What's New in 0.9.0" section
  - Container image references (Quay.io and Docker Hub)
  - Direct download links for RPM/DEB packages
  - Enhanced "Upgrading" section with migration guide link

### Changed

#### Environment Variable Updates (Backward Compatible)
Updated 12 environment variables from `INFLUXDB3_ENTERPRISE_*` to `INFLUXDB3_*` prefix:
- `INFLUXDB3_ENTERPRISE_ADMIN_TOKEN` → `INFLUXDB3_ADMIN_TOKEN`
- `INFLUXDB3_ENTERPRISE_ADMIN_TOKEN_RECOVERY_HTTP_BIND` → `INFLUXDB3_ADMIN_TOKEN_RECOVERY_HTTP_BIND`
- `INFLUXDB3_ENTERPRISE_CLUSTER_ID` → `INFLUXDB3_CLUSTER_ID`
- `INFLUXDB3_ENTERPRISE_NODE_ID` → `INFLUXDB3_NODE_ID`
- `INFLUXDB3_ENTERPRISE_CLUSTER_REPLICATION_INTERVAL` → `INFLUXDB3_CLUSTER_REPLICATION_INTERVAL`
- `INFLUXDB3_ENTERPRISE_SERVE_MODE` → `INFLUXDB3_SERVE_MODE`
- `INFLUXDB3_ENTERPRISE_NUM_CLUSTER_PEERS` → `INFLUXDB3_NUM_CLUSTER_PEERS`
- `INFLUXDB3_ENTERPRISE_NUM_PARTITION_WRITERS` → `INFLUXDB3_NUM_PARTITION_WRITERS`
- `INFLUXDB3_ENTERPRISE_PARTITION_WRITERS_MODE` → `INFLUXDB3_PARTITION_WRITERS_MODE`
- `INFLUXDB3_ENTERPRISE_PROCESSING_ENGINE_ENABLED` → `INFLUXDB3_PROCESSING_ENGINE_ENABLED`
- `INFLUXDB3_ENTERPRISE_BOOTSTRAP_AUTH_TRUST_EXISTING_CLUSTER_ADMINS` → `INFLUXDB3_BOOTSTRAP_AUTH_TRUST_EXISTING_CLUSTER_ADMINS`
- `INFLUXDB3_ENTERPRISE_DEFAULT_ADMIN_USERNAME` → `INFLUXDB3_DEFAULT_ADMIN_USERNAME`

**Note:** Old names still work in InfluxDB 3.11 with deprecation warnings (backward compatible).

#### WAL Configuration Updates (Backward Compatible)
Updated 3 WAL variables across all StatefulSets:
- `WAL_SNAPSHOT_SIZE` → `WAL_FILES_PER_SNAPSHOT`
- `WAL_MAX_WRITE_BUFFER_SIZE` → `WAL_MAX_BUFFERED_WRITES`
- `NUM_WAL_FILES_TO_KEEP` → `SNAPSHOTTED_WAL_FILES_TO_KEEP`

**Note:** Old names still work in InfluxDB 3.11 with deprecation warnings (backward compatible).

#### Memory Configuration Update (Format Change)
- Renamed `EXEC_MEM_POOL_BYTES` → `EXEC_MEM_POOL_SIZE`
- **Format change:** Now requires unit suffix (e.g., `"2GB"`, `"512MB"`)
- Bare numbers (e.g., `2147483648`) are **rejected** by InfluxDB 3.11
- Chart automatically applies correct format

#### Chart Metadata
- **Chart version:** 0.8.0 → 0.9.0
- **App version:** 3.9.3 → 3.11.0
- Default image now references InfluxDB 3.11.0-enterprise

### Removed

#### Deprecated Configuration Options
- Removed `objectStorage.cacheEndpoint` - Object store cache is now automatically configured
- Removed `dataLifecycle.hardDeleteDefaultDuration` - Hard delete duration is now cluster-level only

**Migration:** Remove these options from `values.yaml` before upgrading. See [MIGRATION-3.11.md](./MIGRATION-3.11.md) for details.

### Fixed
- Memory pool configuration now uses correct size format with units (prevents InfluxDB startup failures)
- ConfigMap correctly applies new environment variable names

### Compatibility

#### Backward Compatibility
- ✅ **Existing clusters upgrade seamlessly** - No data migration required
- ✅ **Old environment variable names still work** - InfluxDB 3.11 accepts both old and new names
- ✅ **Existing Parquet clusters stay on Parquet** - Migration to PachaTree is opt-in
- ✅ **No breaking changes to existing configurations** - Only removed options cause issues (2 options removed)

#### Breaking Changes for Specific Configurations
- ❌ **If using `objectStorage.cacheEndpoint`** → Remove from values file (now automatic)
- ❌ **If using `dataLifecycle.hardDeleteDefaultDuration`** → Remove from values file (cluster-level only)
- ⚠️ **If overriding `memory.execMemPoolBytes`** → Update to use size format with units (e.g., `"2GB"`)

#### Upgrade Path
```
Chart 0.8.0 (InfluxDB 3.9.x)
         ↓
    [Upgrade]
         ↓
Chart 0.9.0 (InfluxDB 3.11.0)
```

**Estimated Downtime:** None (rolling update)

### Container Images

#### Quay.io (Recommended)
- Enterprise: `quay.io/influxdb/influxdb3-enterprise:e5242f505d23039a340d21693a994b1a053b0f15`
- Core: `quay.io/influxdb/influxdb3-core:139bab4c54b54db01d67539b6dc9f1e1a81dd1b7`

#### Docker Hub
- Enterprise: `docker.io/influxdb/influxdb3-enterprise:3.11.0-enterprise`
- Core: `docker.io/influxdb/influxdb3-core:3.11.0-core`

#### Direct Downloads
- Enterprise x86_64 RPM: https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise-3.11.0.x86_64.rpm
- Enterprise aarch64 RPM: https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise-3.11.0.aarch64.rpm
- Enterprise amd64 DEB: https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise_3.11.0-1_amd64.deb
- Enterprise arm64 DEB: https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise_3.11.0-1_arm64.deb
- Core x86_64 RPM: https://dl.influxdata.com/influxdb/releases/influxdb3-core-3.11.0.x86_64.rpm
- Core aarch64 RPM: https://dl.influxdata.com/influxdb/releases/influxdb3-core-3.11.0.aarch64.rpm
- Core amd64 DEB: https://dl.influxdata.com/influxdb/releases/influxdb3-core_3.11.0-1_amd64.deb
- Core arm64 DEB: https://dl.influxdata.com/influxdb/releases/influxdb3-core_3.11.0-1_arm64.deb

### Files Changed

| File | Changes |
|------|---------|
| `Chart.yaml` | Version 0.8.0 → 0.9.0, appVersion 3.9.3 → 3.11.0 |
| `values.yaml` | +45 lines: engine, shutdown, processingEngine sections |
| `templates/configmap.yaml` | +18 lines: 12 env var renames, shutdown config |
| `templates/_helpers.tpl` | +30 lines: PachaTree env var helper |
| `templates/ingester-statefulset.yaml` | +5 lines: PachaTree args + env vars |
| `templates/querier-statefulset.yaml` | +5 lines: PachaTree args + env vars |
| `templates/compactor-statefulset.yaml` | +5 lines: PachaTree args + env vars |
| `templates/processor-statefulset.yaml` | +8 lines: Processing Engine env vars |
| `README.md` | Enhanced with 3.11 information, image references |
| `MIGRATION-3.11.md` | New 25KB migration guide |
| `CHANGELOG.md` | This file |

### Migration Guide

For detailed upgrade instructions, troubleshooting, and PachaTree migration steps, see:
- [MIGRATION-3.11.md](./MIGRATION-3.11.md) - Comprehensive upgrade guide
- [README.md#upgrading](./README.md#upgrading) - Quick upgrade steps

### Support

- **Documentation:** [docs.influxdata.com/influxdb3](https://docs.influxdata.com/influxdb3/)
- **Community:** [community.influxdata.com](https://community.influxdata.com)
- **Support Portal:** [support.influxdata.com](https://support.influxdata.com)
- **GitHub Issues:** [github.com/influxdata/helm-charts/issues](https://github.com/influxdata/helm-charts/issues)

---

## [0.8.0] - Previous Release

(Previous changelog entries would go here)

---

**Legend:**
- **Added** - New features
- **Changed** - Changes to existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security fixes
