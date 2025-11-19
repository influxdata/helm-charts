# InfluxDB 3 Enterprise Troubleshooting Guide

This guide helps diagnose and resolve common issues with InfluxDB 3 Enterprise deployments on Kubernetes.

## Table of Contents

- [Pod Issues](#pod-issues)
- [License Issues](#license-issues)
- [Storage Issues](#storage-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)
- [Ingress Issues](#ingress-issues)
- [Processing Engine Issues](#processing-engine-issues)

---

## Pod Issues

### Pods Stuck in Pending State

**Symptoms:**
```bash
kubectl get pods -n influxdb3
NAME                                  READY   STATUS    RESTARTS   AGE
influxdb3-enterprise-ingester-0       0/1     Pending   0          5m
```

**Diagnosis:**
```bash
kubectl describe pod -n influxdb3 influxdb3-enterprise-ingester-0
```

**Common Causes:**

1. **Insufficient Resources**
    - Check node resources: `kubectl top nodes`
    - Solution: Add more nodes or reduce resource requests

2. **PVC Not Bound**
    - Check PVC status: `kubectl get pvc -n influxdb3`
    - Solution: Verify StorageClass exists and can provision volumes

3. **Node Selector/Affinity**
    - Check if nodes match selector
    - Solution: Adjust `nodeSelector` or `affinity` in values.yaml

### Pods CrashLooping

**Symptoms:**
```bash
NAME                                  READY   STATUS             RESTARTS   AGE
influxdb3-enterprise-ingester-0       0/1     CrashLoopBackOff   5          5m
```

**Diagnosis:**
```bash
# Check recent logs
kubectl logs -n influxdb3 influxdb3-enterprise-ingester-0

# Check previous container logs
kubectl logs -n influxdb3 influxdb3-enterprise-ingester-0 --previous
```

**Common Causes:**

1. **License Not Configured**
    - Error: `License email not provided`
    - Solution: Set `license.email` in values.yaml

2. **Object Storage Connection Failed**
    - Error: `Failed to connect to object store`
    - Solution: Verify credentials and endpoint configuration

3. **Cluster ID Conflicts**
    - Error: `cluster-id cannot match any node-id`
    - Solution: Ensure `cluster.id` is different from all node IDs

### Pods Not Ready

**Symptoms:**
```bash
NAME                                  READY   STATUS    RESTARTS   AGE
influxdb3-enterprise-querier-0        0/1     Running   0          5m
```

**Diagnosis:**
```bash
# Check readiness probe
kubectl describe pod -n influxdb3 influxdb3-enterprise-querier-0 | grep -A5 Readiness

# Check /health endpoint
kubectl exec -n influxdb3 influxdb3-enterprise-querier-0 -- curl -s http://localhost:8181/health
```

**Solutions:**
- Increase `readinessProbe.initialDelaySeconds`
- Check object storage connectivity
- Verify catalog synchronization

---

## License Issues

### License Email Not Accepted

**Error Message:**
```
Failed to activate license: invalid email format
```

**Solution:**
1. Verify email format in secret:
   ```bash
   kubectl get secret -n influxdb3 influxdb3-enterprise-license -o jsonpath='{.data.license-email}' | base64 -d
   ```

2. Update license:
   ```bash
   kubectl delete secret -n influxdb3 influxdb3-enterprise-license
   helm upgrade influxdb3-enterprise . -n influxdb3 -f my-values.yaml
   ```

### License Expired

**Error Message:**
```
License expired. Queries are disabled.
```

**Solution:**
- For trial licenses: Contact InfluxData for extension or purchase commercial license
- For commercial licenses: Renew with InfluxData Sales

**Workaround** (check status only):
```bash
# Writes still work, but queries don't
# Check license expiration
kubectl logs -n influxdb3 influxdb3-enterprise-ingester-0 | grep -i license
```

---

## Storage Issues

### Object Storage Connection Failed

**Error Message:**
```
Failed to connect to object store: connection refused
```

**Diagnosis:**

1. **Check S3 credentials:**
   ```bash
   kubectl get secret -n influxdb3 influxdb3-enterprise-object-storage -o yaml
   ```

2. **Test S3 connectivity from pod:**
   ```bash
   kubectl run -it --rm aws-cli --image=amazon/aws-cli --restart=Never -- \
     s3 ls s3://your-bucket --region us-east-1
   ```

3. **Verify endpoint (for S3-compatible):**
   ```bash
   kubectl exec -n influxdb3 influxdb3-enterprise-ingester-0 -- \
     curl -v http://minio.minio.svc.cluster.local:9000
   ```

**Solutions:**

- **AWS S3**: Verify IAM permissions include s3:GetObject, s3:PutObject, s3:ListBucket
- **MinIO**: Check MinIO service is running: `kubectl get svc -n minio`
- **Endpoint**: Ensure `objectStorage.s3.endpoint` is correct
- **Credentials**: Rotate and update access keys

### PVC Not Binding

**Error:**
```bash
kubectl get pvc -n influxdb3
NAME                              STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS
data-influxdb3-enterprise-ingester-0   Pending                                  gp3
```

**Diagnosis:**
```bash
kubectl describe pvc -n influxdb3 data-influxdb3-enterprise-ingester-0
```

**Common Causes:**

1. **StorageClass Doesn't Exist**
   ```bash
   kubectl get storageclass
   ```
   Solution: Create StorageClass or use existing one

2. **No Provisioner**
    - Solution: Install CSI driver for your cloud provider

3. **Insufficient Capacity**
    - Solution: Increase node storage or reduce PVC size

### WAL Disk Full

**Error Message:**
```
WAL directory full, cannot accept more writes
```

**Solution:**

1. **Increase PVC size:**
   ```yaml
   ingester:
     persistence:
       size: "20Gi"  # Increase from 10Gi
   ```

2. **Force snapshot creation:**
   ```bash
   kubectl exec -n influxdb3 influxdb3-enterprise-ingester-0 -- \
     influxdb3 admin force-snapshot --token <admin-token>
   ```

3. **Adjust WAL settings:**
   ```yaml
   wal:
     flushInterval: "500ms"  # More frequent flushes
     snapshotSize: 300       # Smaller snapshots
   ```

---

## Network Issues

### Cannot Access Ingress

**Diagnosis:**

1. **Check Ingress status:**
   ```bash
   kubectl get ingress -n influxdb3
   kubectl describe ingress -n influxdb3 influxdb3-enterprise-write
   ```

2. **Check Ingress Controller:**
   ```bash
   kubectl get pods -n ingress-nginx
   ```

3. **Test internal connectivity:**
   ```bash
   kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- \
     curl http://influxdb3-enterprise-ingester.influxdb3.svc.cluster.local:8181/health
   ```

**Solutions:**

- Verify DNS points to ingress controller external IP
- Check TLS certificate (if enabled): `kubectl get certificate -n influxdb3`
- Verify ingress class exists: `kubectl get ingressclass`

### Network Policy Blocking Traffic

**Symptoms:**
- Pods can't communicate
- Ingress traffic blocked
- Object storage unreachable

**Diagnosis:**
```bash
kubectl get networkpolicy -n influxdb3
kubectl describe networkpolicy -n influxdb3
```

**Solution:**

1. **Temporarily disable:**
   ```yaml
   networkPolicy:
     enabled: false
   ```

2. **Check CNI plugin:**
   ```bash
   kubectl get pods -n kube-system | grep -E 'calico|cilium|weave'
   ```

3. **Adjust policy:**
   ```yaml
   networkPolicy:
     egress:
       toObjectStorage: true  # Ensure enabled
   ```

---

## Performance Issues

### High Write Latency

**Symptoms:**
- Slow write operations
- Increasing write queue

**Diagnosis:**

1. **Check ingester CPU:**
   ```bash
   kubectl top pod -n influxdb3 | grep ingester
   ```

2. **Check IO threads:**
   ```bash
   kubectl logs -n influxdb3 influxdb3-enterprise-ingester-0 | grep "io_worker"
   ```

**Solutions:**

1. **Increase IO threads:**
   ```yaml
   ingester:
     threads:
       io: 16  # Increase from 12
   ```

2. **Scale ingesters horizontally:**
   ```yaml
   ingester:
     replicas: 4  # Increase from 2
   ```

3. **Optimize WAL:**
   ```yaml
   wal:
     flushInterval: "500ms"  # More frequent flushes
   ```

### Slow Queries

**Symptoms:**
- High query latency
- Timeout errors

**Diagnosis:**

1. **Check querier resources:**
   ```bash
   kubectl top pod -n influxdb3 | grep querier
   ```

2. **Check query logs:**
   ```bash
   kubectl exec -n influxdb3 influxdb3-enterprise-querier-0 -- \
     influxdb3 query _internal \
     "SELECT * FROM system.queries ORDER BY issue_time DESC LIMIT 10" \
     --token <admin-token>
   ```

**Solutions:**

1. **Increase DataFusion threads:**
   ```yaml
   querier:
     threads:
       datafusion: 32  # Increase from 28
   ```

2. **Increase Parquet cache:**
   ```yaml
   querier:
     cache:
       parquetSize: "8GB"  # Increase from 4GB
   ```

3. **Scale queriers:**
   ```yaml
   querier:
     replicas: 4  # Increase from 2
   ```

### Compaction Falling Behind

**Symptoms:**
- Many small Parquet files
- Increasing query time

**Diagnosis:**
```bash
kubectl exec -n influxdb3 influxdb3-enterprise-querier-0 -- \
  influxdb3 query _internal \
  "SELECT COUNT(*) FROM system.parquet_files" \
  --token <admin-token>
```

**Solutions:**

1. **Increase compactor resources:**
   ```yaml
   compactor:
     resources:
       requests:
         cpu: "8000m"
     threads:
       datafusion: 40
   ```

2. **Adjust compaction intervals:**
   ```yaml
   compactor:
     compaction:
       checkInterval: "5s"  # More frequent checks
   ```

---

## Ingress Issues

### 502 Bad Gateway

**Diagnosis:**
```bash
kubectl logs -n ingress-nginx <ingress-controller-pod> | grep influxdb
```

**Solutions:**
- Verify backend service exists: `kubectl get svc -n influxdb3`
- Check pod readiness: `kubectl get pods -n influxdb3`
- Increase proxy timeout:
  ```yaml
  ingress:
    write:
      annotations:
        nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
  ```

### SSL Certificate Issues

**Error:** `x509: certificate signed by unknown authority`

**Solutions:**
1. **Check cert-manager:**
   ```bash
   kubectl get certificate -n influxdb3
   kubectl describe certificate -n influxdb3
   ```

2. **Manual certificate:**
   ```bash
   kubectl create secret tls influxdb-tls \
     --cert=path/to/tls.crt \
     --key=path/to/tls.key \
     -n influxdb3
   ```

---

## Processing Engine Issues

### Plugins Not Loading

**Error:** `Plugin file not found`

**Diagnosis:**
```bash
kubectl exec -n influxdb3 influxdb3-enterprise-processor-0 -- \
  ls -la /plugins
```

**Solutions:**

1. **Verify PVC mounted:**
   ```bash
   kubectl describe pod -n influxdb3 influxdb3-enterprise-processor-0 | grep -A5 Mounts
   ```

2. **Check plugin permissions:**
   ```bash
   kubectl exec -n influxdb3 influxdb3-enterprise-processor-0 -- \
     chmod -R 755 /plugins
   ```

### Python Package Installation Failed

**Error:** `Failed to install package: pip not found`

**Solution:**

Check package manager setting:
```yaml
processingEngine:
  packageManager: "discover"  # or "pip", "uv"
```

Install packages manually:
```bash
kubectl exec -it -n influxdb3 influxdb3-enterprise-processor-0 -- \
  influxdb3 install package pandas --token <admin-token>
```

---

## Getting Additional Help

### Collect Debug Information

```bash
# Helm release info
helm get values influxdb3-enterprise -n influxdb3

# Pod status
kubectl get pods -n influxdb3 -o wide

# Recent events
kubectl get events -n influxdb3 --sort-by='.lastTimestamp'

# Logs from all components
kubectl logs -n influxdb3 -l app.kubernetes.io/instance=influxdb3-enterprise --tail=100
```

### Contact Support

For Enterprise customers:
- Email: support@influxdata.com
- Include: Helm chart version, Kubernetes version, logs, and error messages

For Community:
- Forum: https://community.influxdata.com/
- Discord: https://discord.gg/influxdata
