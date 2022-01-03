# InfluxDB v2 Helm chart

[InfluxDB](https://github.com/influxdata/influxdb) is an open source time series
database with no external dependencies. It's useful for recording metrics,
events, and performing analytics.

The InfluxDB v2 Helm chart uses the [Helm](https://helm.sh) package manager to
bootstrap an InfluxDB v2 StatefulSet and service on a
[Kubernetes](http://kubernetes.io) cluster.

## Prerequisites

- Helm v3 or later
- Kubernetes 1.4+
- (Optional) PersistentVolume (PV) provisioner support in the underlying infrastructure

## Install the chart

1. Add the InfluxData Helm repository:

   ```bash
   helm repo add influxdata https://helm.influxdata.com/
   ```

2. Run the following command, providing a name for your InfluxDB release:

   ```bash
   helm upgrade --install my-release influxdata/influxdb2
   ```

   > **Tip**: `--install` can be shortened to `-i`.

   This command deploys InfluxDB v2 on the Kubernetes cluster using the default configuration.

  > **Tip**: To view all Helm chart releases, run `helm list`.

## Uninstall the chart

To uninstall the `my-release` deployment, use the following command:

```bash
helm uninstall my-release
```

This command removes all Kubernetes components associated with the chart and deletes the release.

## Persistence

The [InfluxDB v2](https://hub.docker.com/_/influxdb/) image stores data in the `/var/lib/influxdb2` directory in the container.

If persistence is enabled, a [Persistent Volume](http://kubernetes.io/docs/user-guide/persistent-volumes/)
associated with StatefulSet is provisioned. The volume is created using dynamic
volume provisioning. In case of a disruption (for example, a node drain),
Kubernetes ensures that the same volume is reattached to the Pod, preventing any
data loss. However, when persistence is **not enabled**, InfluxDB data is stored
in an empty directory, so if a Pod restarts, data is lost.

Check out our [Slack channel](https://www.influxdata.com/slack) for support and information.

## Fixed Auth Credentials

If you need to use fixed token and/or password you can set the values
`adminUser.password` and `adminUser.token` or you can use an existing secret,
which would be a better approach.

Example Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: influxdb-auth
type: Opaque
data:
  admin-password: ...
  admin-token: ...
```

If you do not specify an existing secret, the admin-password and admin-token
will be automatically generated. They will remain consistent even after
`helm upgrade`.

## Influx setup

By default this chart uses the docker hub influxdb image which includes an
entrypoint for automatically setting up InfluxDB. This operation is idempotent
and will be skipped if a boltdb is found on startup.

For more information see "Automated Setup" in the [docker image README](https://hub.docker.com/_/influxdb).

For configuration options see `adminUser` in `values.yaml`.

## Configuration

Extra environment variables can be passed influxdb using `.Values.env`. For
example:

```yaml
env:
  - name: FOO
    value: BAR
  - name: BAZ
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: my-key
```
