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
