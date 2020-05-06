# InfluxDB

**Warning**: This InfluxDB Helm chart and the software it deploys are in a beta phase.

[InfluxDB](https://github.com/influxdata/influxdb) is an open source time series database with no external dependencies. It's useful for recording metrics, events, and performing analytics.

## QuickStart

```bash
helm repo add influxdata https://helm.influxdata.com/
helm upgrade --install influxdb influxdata/influxdb2 --namespace monitoring
```

> **Tip**: `--install` can be shortened to `-i`.

## Introduction

This chart bootstraps an InfluxDB v2 StatefulSet and service on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.4+
- (Optional) PV provisioner support in the underlying infrastructure

## Installing the chart

To install the chart with the release name `my-release`, use the following command:

```bash
helm upgrade --install my-release influxdata/influxdb2
```

This command deploys InfluxDB on the Kubernetes cluster using the default configuration.

To find parameters you can configure during installation, see [Configuration](#configuration).

> **Tip**: To view all releases, run `helm list`.

## Uninstalling the chart

To uninstall the `my-release` deployment, use the following command:

```bash
helm uninstall my-release
```

This command removes all Kubernetes components associated with the chart and deletes the release.

## Persistence

The [InfluxDB](https://quay.io/influxdb/influxdb:2.0.0-beta) image stores data in the `/root/.influxdbv2` directory in the container.

If persistence is enabled, a [Persistent Volume](http://kubernetes.io/docs/user-guide/persistent-volumes/) associated with StatefulSet is provisioned. The volume is created using dynamic volume provisioning. In case of a disruption, for example, a node drain, Kubernetes ensures that the same volume is reattached to the Pod, preventing any data loss. Although, when persistence is not enabled, InfluxDB data is stored in an empty directory thus, in a Pod restart, data is lost.

Check out our [Slack channel](https://www.influxdata.com/slack) for support and information.