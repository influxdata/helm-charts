# Telegraf-DS (DaemonSet)

[Telegraf](https://github.com/influxdata/telegraf) is a plugin-driven server agent written by the folks over at [InfluxData](https://influxdata.com) for collecting & reporting metrics. This chart runs a DaemonSet of Telegraf instances to collect host level metrics for your cluster. If you need to poll individual instances of infrastructure or APIs there is a `telegraf` chart that is more suited to that usecase.

For this chart, Telegraf inputs cannot be customised as it aims to provide an opinionated configuration to monitor kubernetes nodes and global kubernetes monitoring.

## TL;DR

```console
helm repo add influxdata https://helm.influxdata.com/
helm upgrade --install telegraf-ds influxdata/telegraf-ds
```

> **Tip**: `helm upgrade --install [RELEASE] [CHART] [FLAGS]` is idempotent and can be run multiple times. If chart was not previously installed, helm will install it. If present, it will redeploy the same version or upgrade it if a new version is available.

## Introduction

This chart bootstraps a `telegraf-ds` DaemonSet on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.11+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm upgrade --install my-release influxdata/telegraf-ds
```

The command deploys a Telegraf DaemonSet on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section as well as the [values.yaml](/values.yaml) file lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm uninstall my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The default configuration parameters are listed in `values.yaml`. To change the defaults, specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
helm upgrade --install my-release \
  --set config.outputs.influxdb.url=http://foo.bar:8086 \
    influxdata/telegraf-ds
```

The above command allows the chart to deploy by setting the InfluxDB URL for telegraf to write to.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
helm upgrade --install my-release -f values.yaml influxdata/telegraf-ds
```

> **Tip**: `helm upgrade --install [RELEASE] [CHART] [FLAGS]` can be shortened : `helm upgrade -i [RELEASE] [CHART] [FLAGS]`

## Telegraf Configuration

This chart deploys the following by default:

- `telegraf` running as a DaemonSet (`telegraf-ds`) with the following plugins enabled
  * [`cpu`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/cpu)
  * [`disk`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/disk)
  * [`diskio`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)
  * [`docker`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/docker)
  * [`kernel`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/kernel)
  * [`kubernetes`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/kubernetes)
  * [`mem`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/mem)
  * [`processes`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/processes)
  * [`swap`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/swap)
  * [`system`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/system)
