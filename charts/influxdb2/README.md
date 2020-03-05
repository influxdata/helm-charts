# InfluxDB

**Warning**: This chart, as well as the software it deploys, is in a BETA phase.

If you're considering deploying this, please also consider using our [Slack channel](https://www.influxdata.com/slack) to get support when needed.

##  An Open-Source Time Series Database

[InfluxDB](https://github.com/influxdata/influxdb) is an open source time series database built by the folks over at [InfluxData](https://influxdata.com) with no external dependencies. It's useful for recording metrics, events, and performing analytics.

## QuickStart

```bash
helm repo add influxdata https://helm.influxdata.com/
helm upgrade --install influxdb influxdata/influxdb2 --namespace monitoring
```

> **Tip**: `helm upgrade --install [RELEASE] [CHART] [FLAGS]` can be shortened : `helm upgrade -i [RELEASE] [CHART] [FLAGS]`

## Introduction

This chart bootstraps an InfluxDB v2 statefulset and service on a Kubernetes cluster using the Helm Package manager.

## Prerequisites

- Kubernetes 1.4+
- PV provisioner support in the underlying infrastructure (optional)

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm upgrade --install my-release influxdata/influxdb2
```

The command deploys InfluxDB on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm uninstall my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.


## Persistence

The [InfluxDB](https://quay.io/influxdb/influxdb:2.0.0-beta) image stores data in the `/root/.influxdbv2` directory in the container.

If persistence is enabled, a [Persistent Volume](http://kubernetes.io/docs/user-guide/persistent-volumes/) associated with Statefulset will be provisioned. The volume is created using dynamic volume provisioning. In case of a disruption e.g. a node drain, kubernetes ensures that the same volume will be reatached to the Pod, preventing any data loss. Althought, when persistence is not enabled, InfluxDB data will be stored in an empty directory thus, in a Pod restart, data will be lost.
