# Migration Guide: InfluxDB 3.11 Helm Chart (v0.9.0)

This guide covers upgrading from Helm chart **v0.8.0** (InfluxDB 3.9.x) to **v0.9.0** (InfluxDB 3.11.0).

---

## Table of Contents

- [Overview](#overview)
- [Breaking Changes Summary](#breaking-changes-summary)
- [New Features](#new-features)
- [Before You Upgrade](#before-you-upgrade)
- [Upgrade Scenarios](#upgrade-scenarios)
  - [Scenario 1: Fresh Install (New Cluster)](#scenario-1-fresh-install-new-cluster)
  - [Scenario 2: Existing Cluster (No Configuration Changes)](#scenario-2-existing-cluster-no-configuration-changes)
  - [Scenario 3: Migrating to PachaTree Storage Engine](#scenario-3-migrating-to-pachatree-storage-engine)
  - [Scenario 4: Using Removed Configuration Options](#scenario-4-using-removed-configuration-options)
- [Post-Upgrade Validation](#post-upgrade-validation)
- [Rollback Procedure](#rollback-procedure)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What Changed

**Chart Version:** 0.8.0 → 0.9.0  
**App Version:** 3.9.3 → 3.11.0  
**Release Date:** July 2026

**Key Changes:**
- ✅ **Backward compatible** - Existing clusters upgrade seamlessly
- 🆕 **PachaTree storage engine** - New default for fresh installs
- ⚙️ **Environment variable renames** - Old names work with deprecation warnings
- 🗑️ **Removed flags** - 2 deprecated options removed
- 🚀 **New features** - Graceful shutdown, Processing Engine updates

### Upgrade Path

```
Chart 0.8.0 (InfluxDB 3.9.x)
         ↓
    [Upgrade]
         ↓
Chart 0.9.0 (InfluxDB 3.11.0)
```

**Estimated Downtime:** None (rolling update)  
**Data Migration:** Not required (unless migrating to PachaTree)

---

## Breaking Changes Summary

### 1. Environment Variable Renames

**12 environment variables** were renamed from `INFLUXDB3_ENTERPRISE_*` to `INFLUXDB3_*`:

| Old Name (0.8.0) | New Name (0.9.0) | Compatibility |
|------------------|------------------|---------------|
| `INFLUXDB3_ENTERPRISE_ADMIN_TOKEN` | `INFLUXDB3_ADMIN_TOKEN` | ✅ Old name works in 3.11 |
| `INFLUXDB3_ENTERPRISE_ADMIN_TOKEN_RECOVERY_HTTP_BIND` | `INFLUXDB3_ADMIN_TOKEN_RECOVERY_HTTP_BIND` | ✅ Old name works in 3.11 |
| `INFLUXDB3_ENTERPRISE_CLUSTER_ID` | `INFLUXDB3_CLUSTER_ID` | ✅ Old name works in 3.11 |
| `INFLUXDB3_ENTERPRISE_NODE_ID` | `INFLUXDB3_NODE_ID` | ✅ Old name works in 3.11 |
| `INFLUXDB3_ENTERPRISE_CLUSTER_REPLICATION_INTERVAL` | `INFLUXDB3_CLUSTER_REPLICATION_INTERVAL` | ✅ Old name works in 3.11 |
| `INFLUXDB3_ENTERPRISE_SERVE_MODE` | `INFLUXDB3_SERVE_MODE` | ✅ Old name works in 3.11 |
| (+ 6 more) | | |

**Impact:** Chart v0.9.0 uses new names. InfluxDB 3.11 accepts both old and new names with deprecation warnings.

**Action Required:** None - upgrade handles this automatically.

### 2. WAL Configuration Changes

**3 WAL variables** were renamed:

| Old Name (0.8.0) | New Name (0.9.0) | Compatibility |
|------------------|------------------|---------------|
| `WAL_SNAPSHOT_SIZE` | `WAL_FILES_PER_SNAPSHOT` | ✅ Old name works in 3.11 |
| `WAL_MAX_WRITE_BUFFER_SIZE` | `WAL_MAX_BUFFERED_WRITES` | ✅ Old name works in 3.11 |
| `NUM_WAL_FILES_TO_KEEP` | `SNAPSHOTTED_WAL_FILES_TO_KEEP` | ✅ Old name works in 3.11 |

**Impact:** All StatefulSets (ingester, querier, compactor, processor) updated.

**Action Required:** None - upgrade handles this automatically.

### 3. Memory Configuration Changes

**1 memory variable** was renamed and **changed format**:

| Old Name (0.8.0) | New Name (0.9.0) | Format Change |
|------------------|------------------|---------------|
| `EXEC_MEM_POOL_BYTES` | `EXEC_MEM_POOL_SIZE` | Now requires unit suffix (e.g., `"1GB"`, `"512MB"`) |

**Impact:** Chart automatically applies correct format.

**Action Required:** 
- If you override `memory.execMemPoolBytes` in your values, update to use size format with units (e.g., `"2GB"`).
- Bare numbers (e.g., `2147483648`) will be **rejected** by InfluxDB 3.11.

### 4. Removed Configuration Options

**2 deprecated options** were removed:

| Removed Option | Replacement | Removal Reason |
|----------------|-------------|----------------|
| `objectStorage.cacheEndpoint` | None (automatic) | Object store cache now auto-configured |
| `dataLifecycle.hardDeleteDefaultDuration` | None | Hard delete duration now cluster-level only |

**Impact:** If you use either option in your `values.yaml`, upgrade will fail with validation error.

**Action Required:** Remove these options from your values file before upgrading.

---

## New Features

### 1. PachaTree Storage Engine 🆕

**What:** Next-generation storage engine with improved compaction performance.

**Behavior:**
- **New clusters:** PachaTree is automatically enabled (no configuration needed)
- **Existing Parquet clusters:** Stay on Parquet until you opt in to migration
- **Migration:** One-time, one-way process (Parquet → PachaTree)

**Configuration:**
```yaml
# For existing Parquet clusters wanting to migrate:
engine:
  upgradePachaTree: true    # Set ONCE to start migration
  
  # Optional: Tune PachaTree behavior
  pachaTree:
    shardCount: 1                    # Number of shards (default: 1)
    maxTotalColumns: 5000            # Max columns across all tables
    snapshotSize: 100000             # Snapshot threshold
    gen0MaxFileSize: "100mb"         # Max Gen0 file size
    walReplicaQueueLength: 1000      # WAL queue length
```

**See:** [Scenario 3: Migrating to PachaTree](#scenario-3-migrating-to-pachatree-storage-engine)

### 2. Graceful Shutdown 🆕

**What:** Configurable timeout for draining active connections before pod shutdown.

**Configuration:**
```yaml
shutdown:
  timeout: "30s"    # Connection drain timeout (default: 30s)
  # timeout: "0s"   # Skip drain entirely (immediate shutdown)
```

**Benefits:**
- Fewer client connection errors during rolling updates
- Better user experience during maintenance
- Reduced load on ingress/load balancers

### 3. Processing Engine Updates 🆕

**What:** Security and performance controls for Processing Engine.

**Configuration:**
```yaml
processingEngine:
  # Security: Block all package install API calls
  disablePackageManagement: false
  
  # Performance: Limit concurrent async trigger invocations
  asyncTriggerConcurrencyLimit: 8    # Default: unlimited
```

**Benefits:**
- `disablePackageManagement: true` → Lock down package installations
- `asyncTriggerConcurrencyLimit` → Prevent runaway async trigger usage

---

## Before You Upgrade

### 1. Check Current Configuration

**Identify your values file:**
```bash
# If you used -f flag during install
cat my-values.yaml

# Or export current values
helm get values influxdb3-enterprise -n influxdb3 > current-values.yaml
```

**Check for removed options:**
```bash
grep -E "cacheEndpoint|hardDeleteDefaultDuration" current-values.yaml
```

If found, remove these lines before upgrading.

### 2. Backup Current State

```bash
# Backup Helm release
helm get all influxdb3-enterprise -n influxdb3 > backup-helm-release.yaml

# Backup values
helm get values influxdb3-enterprise -n influxdb3 > backup-values.yaml

# Backup Kubernetes resources
kubectl get all -n influxdb3 -o yaml > backup-k8s-resources.yaml
```

### 3. Check Cluster Health

```bash
# Check all pods are healthy
kubectl get pods -n influxdb3

# Check recent errors (should be minimal)
kubectl logs -n influxdb3 -l app.kubernetes.io/name=influxdb3-enterprise \
  --tail=100 --since=10m | grep -i error
```

**Do not upgrade if:**
- Any pods are in `CrashLoopBackOff` or `Error` state
- High error rate in logs
- Active compaction issues
- Object store connectivity problems

### 4. Prepare Updated Values File

**If using removed options:**
```yaml
# OLD (0.8.0) - REMOVE THESE
objectStorage:
  cacheEndpoint: "http://cache.example.com"  # ❌ REMOVE

dataLifecycle:
  hardDeleteDefaultDuration: "7d"            # ❌ REMOVE
```

**Updated (0.9.0):**
```yaml
# NEW - These options no longer exist
# Object store cache is now automatic
# Hard delete duration is cluster-level only
```

### 5. Review Storage Engine Decision

**Decision tree:**

```
Are you running an EXISTING cluster?
  ├─ Yes → Stay on Parquet (upgrade normally)
  │         Later: Optionally migrate to PachaTree
  │
  └─ No (fresh install) → PachaTree automatically
                          (no configuration needed)
```

---

## Upgrade Scenarios

### Scenario 1: Fresh Install (New Cluster)

**Situation:** Installing InfluxDB 3 Enterprise for the first time.

**Behavior:** PachaTree storage engine is automatically enabled.

**Steps:**

1. **Pull new chart version:**
   ```bash
   helm repo update influxdata
   ```

2. **Create values file:**
   ```yaml
   # values.yaml
   cluster:
     id: "my-new-cluster"
   
   objectStorage:
     type: s3
     bucket: "my-bucket"
     s3:
       region: "us-east-1"
       accessKeyId: "YOUR_KEY"
       secretAccessKey: "YOUR_SECRET"
   
   license:
     type: "trial"
     email: "user@example.com"
   
   # No engine configuration needed - PachaTree is automatic
   ```

3. **Install:**
   ```bash
   helm install influxdb3-enterprise influxdata/influxdb3-enterprise \
     --version 0.9.0 \
     --namespace influxdb3 \
     --create-namespace \
     -f values.yaml
   ```

4. **Verify PachaTree is active:**
   ```bash
   kubectl logs -n influxdb3 \
     $(kubectl get pods -n influxdb3 -l app.kubernetes.io/component=ingester -o name | head -1) \
     | grep -i "storage engine"
   ```

   Expected: Log message indicating PachaTree engine active.

---

### Scenario 2: Existing Cluster (No Configuration Changes)

**Situation:** Upgrading existing cluster, staying on Parquet storage.

**Behavior:** Cluster stays on Parquet engine (backward compatible).

**Steps:**

1. **Backup current state:** (see [Before You Upgrade](#before-you-upgrade))

2. **Clean up values file** (if using removed options):
   ```bash
   # Edit your values file and remove:
   # - objectStorage.cacheEndpoint
   # - dataLifecycle.hardDeleteDefaultDuration
   ```

3. **Update Helm repository:**
   ```bash
   helm repo update influxdata
   ```

4. **Upgrade:**
   ```bash
   helm upgrade influxdb3-enterprise influxdata/influxdb3-enterprise \
     --version 0.9.0 \
     --namespace influxdb3 \
     -f my-values.yaml
   ```

5. **Watch rolling update:**
   ```bash
   kubectl rollout status statefulset/influxdb3-enterprise-ingester -n influxdb3
   kubectl rollout status statefulset/influxdb3-enterprise-querier -n influxdb3
   kubectl rollout status statefulset/influxdb3-enterprise-compactor -n influxdb3
   kubectl rollout status statefulset/influxdb3-enterprise-processor -n influxdb3
   ```

6. **Verify cluster health:** (see [Post-Upgrade Validation](#post-upgrade-validation))

**Expected Outcome:**
- Pods restart with new image (`3.11.0-enterprise`)
- Cluster continues running on Parquet engine
- Environment variables use new names (old names logged as deprecated)
- No data migration

**Estimated Time:** 10-20 minutes (depends on pod count and restart speed)

---

### Scenario 3: Migrating to PachaTree Storage Engine

**Situation:** Existing Parquet cluster wants to migrate to PachaTree.

**⚠️ IMPORTANT:**
- Migration is **one-way** (Parquet → PachaTree, no rollback)
- Cluster enters hybrid `ParquetAndPachaTree` mode during migration
- Migration runs in background (cluster stays online)
- Duration varies by data volume (can take hours to days)

**Prerequisites:**
- Cluster is healthy (check logs and metrics)
- Sufficient object store space for temporary dual-engine data
- Backup completed (see [Before You Upgrade](#before-you-upgrade))
- **Migration occurs during low-traffic window** (optional but recommended)

**Steps:**

1. **Update values file with migration flag:**
   ```yaml
   # my-values.yaml
   
   # Enable PachaTree migration
   engine:
     upgradePachaTree: true    # Set ONCE to start migration
   
   # Optional: Tune PachaTree behavior
   # engine:
   #   pachaTree:
   #     shardCount: 2                    # More shards = more parallelism
   #     maxTotalColumns: 10000           # Higher column limit
   #     snapshotSize: 200000             # Larger snapshots
   #     gen0MaxFileSize: "200mb"         # Larger Gen0 files
   #     walReplicaQueueLength: 2000      # Larger WAL queue
   
   # ... rest of your existing configuration ...
   ```

2. **Upgrade chart:**
   ```bash
   helm upgrade influxdb3-enterprise influxdata/influxdb3-enterprise \
     --version 0.9.0 \
     --namespace influxdb3 \
     -f my-values.yaml
   ```

3. **Monitor migration progress:**
   ```bash
   # Watch for "ParquetAndPachaTree" mode in logs
   kubectl logs -n influxdb3 -l app.kubernetes.io/name=influxdb3-enterprise --tail=50 -f \
     | grep -i "storage engine"
   
   # Check for migration completion
   kubectl logs -n influxdb3 -l app.kubernetes.io/component=compactor --tail=100 -f \
     | grep -i "pacha"
   ```

   **Expected log messages:**
   - `Storage engine mode: ParquetAndPachaTree` ← Migration started
   - `Compacting Parquet files to PachaTree...` ← Migration in progress
   - `Storage engine mode: PachaTree` ← Migration complete

4. **Wait for migration completion:**
   
   **Signs migration is complete:**
   - All nodes log `Storage engine mode: PachaTree`
   - No more `ParquetAndPachaTree` messages in logs
   - Compaction logs show only PachaTree operations
   
   **Duration estimates:**
   - Small cluster (<100GB): 30 minutes - 2 hours
   - Medium cluster (100GB-1TB): 2-8 hours
   - Large cluster (>1TB): 8-48+ hours

5. **Validate migration success:**
   ```bash
   # Query data to verify read path works
   influx3 query \
     --host https://your-cluster.example.com \
     --token YOUR_TOKEN \
     --database mydb \
     --query "SELECT * FROM my_measurement LIMIT 10"
   
   # Write data to verify write path works
   influx3 write \
     --host https://your-cluster.example.com \
     --token YOUR_TOKEN \
     --database mydb \
     "my_measurement,tag1=value1 field1=1.0"
   ```

6. **Remove migration flag** (after validation):
   ```yaml
   # my-values.yaml
   
   # Remove or set to false (migration is one-time)
   engine:
     upgradePachaTree: false    # Or remove this section entirely
   
   # Optional: Keep PachaTree tuning config
   # engine:
   #   pachaTree:
   #     shardCount: 2
   #     # ... other tuning ...
   ```

7. **Apply updated values:**
   ```bash
   helm upgrade influxdb3-enterprise influxdata/influxdb3-enterprise \
     --version 0.9.0 \
     --namespace influxdb3 \
     -f my-values.yaml
   ```

**Troubleshooting Migration:**

- **Migration stuck?** Check compactor logs for errors:
  ```bash
  kubectl logs -n influxdb3 -l app.kubernetes.io/component=compactor --tail=500
  ```

- **High error rate?** Check object store connectivity and permissions.

- **Need to pause?** Not recommended mid-migration. Contact InfluxData support.

---

### Scenario 4: Using Removed Configuration Options

**Situation:** Your `values.yaml` contains `objectStorage.cacheEndpoint` or `dataLifecycle.hardDeleteDefaultDuration`.

**Error during upgrade:**
```
Error: UPGRADE FAILED: values don't meet the specifications of the schema(s) in the following chart(s):
influxdb3-enterprise:
- objectStorage.cacheEndpoint: Unsupported property
```

**Steps:**

1. **Identify removed options:**
   ```bash
   grep -E "cacheEndpoint|hardDeleteDefaultDuration" my-values.yaml
   ```

2. **Remove them:**
   ```yaml
   # OLD (0.8.0)
   objectStorage:
     type: s3
     bucket: "my-bucket"
     cacheEndpoint: "http://cache.example.com"  # ❌ REMOVE THIS LINE
     s3:
       region: "us-east-1"
   
   dataLifecycle:
     hardDeleteDefaultDuration: "7d"            # ❌ REMOVE THIS LINE
   ```

   ```yaml
   # NEW (0.9.0)
   objectStorage:
     type: s3
     bucket: "my-bucket"
     # cacheEndpoint removed - now automatic
     s3:
       region: "us-east-1"
   
   dataLifecycle:
     # hardDeleteDefaultDuration removed - cluster-level only
     # Other dataLifecycle options still work:
     enabled: true
     ttlCheckInterval: "1h"
   ```

3. **Upgrade:**
   ```bash
   helm upgrade influxdb3-enterprise influxdata/influxdb3-enterprise \
     --version 0.9.0 \
     --namespace influxdb3 \
     -f my-values.yaml
   ```

---

## Post-Upgrade Validation

### 1. Check Pod Status

```bash
# All pods should be Running
kubectl get pods -n influxdb3

# Check for recent restarts or errors
kubectl get pods -n influxdb3 -o wide
```

**Expected:** All pods in `Running` state with `READY 1/1`.

### 2. Check Image Version

```bash
# Verify all pods are running 3.11.0
kubectl get pods -n influxdb3 -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

**Expected:** All images show version `3.11.0-enterprise` (or your specified tag).

### 3. Check Logs for Errors

```bash
# Check for critical errors
kubectl logs -n influxdb3 -l app.kubernetes.io/name=influxdb3-enterprise \
  --tail=200 --since=10m | grep -E "ERROR|FATAL|panic"

# Check for deprecation warnings (expected after upgrade)
kubectl logs -n influxdb3 -l app.kubernetes.io/name=influxdb3-enterprise \
  --tail=200 --since=10m | grep -i "deprecated"
```

**Expected:**
- No `ERROR`, `FATAL`, or `panic` messages
- Deprecation warnings for old environment variable names (harmless)

### 4. Test Write Path

```bash
# Write test data
curl -X POST "https://your-cluster.example.com/api/v3/write?db=_test" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d "test_measurement,tag1=value1 field1=1.0 $(date +%s)000000000"
```

**Expected:** HTTP 204 (success).

### 5. Test Read Path

```bash
# Query test data
curl -G "https://your-cluster.example.com/api/v3/query?db=_test" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  --data-urlencode "q=SELECT * FROM test_measurement LIMIT 1"
```

**Expected:** JSON response with data.

### 6. Check Storage Engine Mode

**For new clusters:**
```bash
kubectl logs -n influxdb3 \
  $(kubectl get pods -n influxdb3 -l app.kubernetes.io/component=ingester -o name | head -1) \
  | grep -i "storage engine"
```

**Expected:** `Storage engine mode: PachaTree`

**For existing Parquet clusters (not migrating):**

**Expected:** `Storage engine mode: Parquet` or no message (Parquet is default).

**For migrating clusters:**

**During migration:** `Storage engine mode: ParquetAndPachaTree`  
**After migration:** `Storage engine mode: PachaTree`

### 7. Check Metrics (if Prometheus enabled)

```bash
# Check compaction metrics
kubectl port-forward -n influxdb3 svc/influxdb3-enterprise-compactor 8086:8086

curl http://localhost:8086/metrics | grep influxdb3_compaction
```

**Expected:** Compaction metrics present and values are reasonable.

---

## Rollback Procedure

### When to Rollback

- Critical errors after upgrade
- Data corruption detected
- Cluster unstable after migration
- **DO NOT rollback after PachaTree migration starts** (one-way process)

### Rollback Steps

1. **Check if PachaTree migration started:**
   ```bash
   kubectl logs -n influxdb3 -l app.kubernetes.io/name=influxdb3-enterprise \
     | grep -i "ParquetAndPachaTree"
   ```

   **If found:** Migration started - **DO NOT ROLLBACK**. Contact InfluxData support.

2. **Rollback Helm release:**
   ```bash
   # Rollback to previous revision
   helm rollback influxdb3-enterprise -n influxdb3
   
   # Or rollback to specific revision
   helm history influxdb3-enterprise -n influxdb3
   helm rollback influxdb3-enterprise 2 -n influxdb3  # Replace 2 with target revision
   ```

3. **Watch pods restart:**
   ```bash
   kubectl get pods -n influxdb3 -w
   ```

4. **Validate cluster health:** (see [Post-Upgrade Validation](#post-upgrade-validation))

### Rollback Limitations

- **Cannot rollback PachaTree migration** (one-way process)
- Environment variable deprecation warnings will appear in logs (harmless)
- If you removed deprecated options from values file, you must re-add them for v0.8.0

---

## Troubleshooting

### Issue: Upgrade fails with "values don't meet specifications"

**Cause:** Using removed configuration options.

**Solution:** Remove `objectStorage.cacheEndpoint` and `dataLifecycle.hardDeleteDefaultDuration` from values file.

**See:** [Scenario 4: Using Removed Configuration Options](#scenario-4-using-removed-configuration-options)

---

### Issue: Pods stuck in `ImagePullBackOff`

**Cause:** Image not found or registry authentication issue.

**Check image:**
```bash
kubectl describe pod <pod-name> -n influxdb3 | grep -A 5 Events
```

**Solutions:**

1. **Use explicit image tag:**
   ```yaml
   image:
     registry: quay.io
     repository: influxdb/influxdb3-enterprise
     tag: "e5242f505d23039a340d21693a994b1a053b0f15"  # 3.11.0 commit SHA
   ```

2. **Or use Docker Hub:**
   ```yaml
   image:
     registry: docker.io
     repository: influxdb/influxdb3-enterprise
     tag: "3.11.0-enterprise"
   ```

3. **Or configure pull secrets:**
   ```yaml
   imagePullSecrets:
     - name: quay-pull-secret
   ```

---

### Issue: Pods crash with "unknown flag" error

**Cause:** Old Helm values using removed flags.

**Check logs:**
```bash
kubectl logs <pod-name> -n influxdb3
```

**Solution:** Remove deprecated options from values file and upgrade again.

---

### Issue: High error rate after upgrade

**Check logs:**
```bash
kubectl logs -n influxdb3 -l app.kubernetes.io/name=influxdb3-enterprise \
  --tail=500 | grep ERROR
```

**Common causes:**
- Object store connectivity issues
- Memory limits too low for new memory format
- PachaTree migration encountering data issues

**Solutions:**
1. Check object store credentials and connectivity
2. Increase memory limits if seeing OOM errors
3. Contact InfluxData support with logs if migration-related

---

### Issue: PachaTree migration stuck

**Check compactor logs:**
```bash
kubectl logs -n influxdb3 -l app.kubernetes.io/component=compactor --tail=500 -f
```

**Common causes:**
- Object store write failures
- Insufficient resources (CPU/memory)
- Data corruption in Parquet files

**Solutions:**
1. Verify object store permissions (read/write/delete)
2. Check compactor pod resources (`kubectl top pod -n influxdb3`)
3. Increase compactor resources if needed
4. Contact InfluxData support if migration fails repeatedly

---

### Issue: Deprecation warnings flooding logs

**Example:**
```
WARN: INFLUXDB3_ENTERPRISE_CLUSTER_ID is deprecated, use INFLUXDB3_CLUSTER_ID
```

**Cause:** Chart v0.9.0 uses new environment variable names. InfluxDB 3.11 still accepts old names with warnings.

**Impact:** Harmless - warnings can be ignored.

**Solution (optional):** Wait for next chart release where these warnings will be suppressed (InfluxDB 3.12+).

---

### Issue: Queries return incomplete data after PachaTree migration

**Cause:** Migration still in progress - cluster in `ParquetAndPachaTree` hybrid mode.

**Check:**
```bash
kubectl logs -n influxdb3 -l app.kubernetes.io/name=influxdb3-enterprise \
  | grep -i "storage engine"
```

**If seeing "ParquetAndPachaTree":** Migration still running - data will be complete when migration finishes.

**If seeing "PachaTree":** Migration complete - queries should return all data.

**If data still missing:** Contact InfluxData support with query examples.

---

## Additional Resources

### Documentation
- [InfluxDB 3.11 Release Notes](https://docs.influxdata.com/influxdb3/enterprise/release-notes/3.11/)
- [PachaTree Storage Engine](https://docs.influxdata.com/influxdb3/enterprise/storage-engines/pachatree/)
- [Helm Chart README](./README.md)
- [Helm Chart Examples](./examples/)

### Container Images

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
- [InfluxDB 3 Enterprise (x86_64 RPM)](https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise-3.11.0.x86_64.rpm)
- [InfluxDB 3 Enterprise (aarch64 RPM)](https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise-3.11.0.aarch64.rpm)
- [InfluxDB 3 Enterprise (amd64 DEB)](https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise_3.11.0-1_amd64.deb)
- [InfluxDB 3 Enterprise (arm64 DEB)](https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise_3.11.0-1_arm64.deb)

### Support
- **Community:** [community.influxdata.com](https://community.influxdata.com)
- **Support Portal:** [support.influxdata.com](https://support.influxdata.com)
- **GitHub Issues:** [github.com/influxdata/helm-charts/issues](https://github.com/influxdata/helm-charts/issues)

---

## Summary Checklist

### Pre-Upgrade
- [ ] Backup current Helm release and values
- [ ] Remove deprecated options from values file
- [ ] Check cluster health (all pods running, low error rate)
- [ ] Decide on storage engine (stay Parquet or migrate to PachaTree)
- [ ] Review breaking changes relevant to your configuration

### During Upgrade
- [ ] Run `helm upgrade` with updated values
- [ ] Watch rolling update progress
- [ ] Monitor logs for errors

### Post-Upgrade
- [ ] Verify all pods running with new image version
- [ ] Test write and read paths
- [ ] Check logs for critical errors
- [ ] Validate storage engine mode
- [ ] Monitor cluster metrics

### PachaTree Migration (if applicable)
- [ ] Set `engine.upgradePachaTree: true` in values
- [ ] Monitor migration progress in logs
- [ ] Wait for migration completion (`Storage engine mode: PachaTree`)
- [ ] Validate data integrity with test queries
- [ ] Remove `upgradePachaTree` flag from values after completion

---

**Questions?** Check [Troubleshooting](#troubleshooting) or contact InfluxData support.

**Version:** 1.0  
**Last Updated:** July 31, 2026  
**Chart Version:** 0.9.0  
**App Version:** 3.11.0
