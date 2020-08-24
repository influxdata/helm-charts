# InfluxDB v2 Helm chart

**Warning**: This InfluxDB Helm chart and the software it deploys are in a beta phase.

[InfluxDB](https://github.com/influxdata/influxdb) is an open source time series database with no external dependencies. It's useful for recording metrics, events, and performing analytics.

The InfluxDB v2 Helm chart uses the [Helm](https://helm.sh) package manager to bootstrap an InfluxDB v2 StatefulSet and service on a [Kubernetes](http://kubernetes.io) cluster.

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

The [InfluxDB](https://quay.io/influxdb/influxdb:2.0.0-beta) image stores data in the `/root/.influxdbv2` directory in the container.

If persistence is enabled, a [Persistent Volume](http://kubernetes.io/docs/user-guide/persistent-volumes/) associated with StatefulSet is provisioned. The volume is created using dynamic volume provisioning. In case of a disruption (for example, a node drain), Kubernetes ensures that the same volume is reattached to the Pod, preventing any data loss. However, when persistence is **not enabled**, InfluxDB data is stored in an empty directory, so if a Pod restarts, data is lost.

Check out our [Slack channel](https://www.influxdata.com/slack) for support and information.

## Fixed Auth Credentials

If you need to use fixed token and/or password you can fill `adminUser.password` and `adminUser.token` on your values file to avoid using random values generation.
