# Manual lifecycle tests

Prerequisites:

- Bash 3.2 or later
- Helm and kubectl
- a running Kubernetes cluster
- a running S3-compatible store reachable from the cluster and configured by `values-s3.yaml`
- an InfluxData commercial license stored outside the repository

Run an upgrade scenario:

```sh
./tests/manual/scenarios/upgrade-3.10-to-3.11.sh \
  --license-file /path/to/commercial-license.txt
```

The scenario creates a unique namespace, bucket, cluster ID, and Helm release.
It prints the raw post-upgrade query result and removes the namespace and
bucket on success or failure.

For 3.11.5 to 3.12.0, use the same options:

```sh
./tests/manual/scenarios/upgrade-3.11-to-3.12.sh \
  --license-file /path/to/commercial-license.txt
```

The scenario starts fresh on published chart 0.15.0 / InfluxDB 3.11.5,
writes baseline data, and upgrades to the local 3.12 chart with
`acknowledgeUpgrade="3.12"` and `--reuse-values`. It verifies the version
on every component before and after the upgrade, then queries both baseline
and post-upgrade data. The storage engine stays unchanged.

Use `--values`, `--context`, and `--s3-endpoint` as in the earlier scenario.
Namespace, bucket, cluster ID, pod names, test Secrets, and cleanup follow
the existing 3.10-to-3.11 scenario.

Reference: [Upgrade InfluxDB 3 Enterprise](https://docs.influxdata.com/influxdb3/enterprise/admin/upgrade/).
