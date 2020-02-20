# Telegraf-DS (DaemonSet)

[Telegraf](https://github.com/influxdata/telegraf) is a plugin-driven server agent written by the folks over at [InfluxData](https://influxdata.com) for collecting & reporting metrics. This chart runs a DaemonSet of Telegraf instances to collect host level metrics for your cluster. If you need to poll individual instances of infrastructure or APIs there is a `telegraf` chart that is more suited to that usecase.

## TL;DR

```console
$ helm repo add influxdata https://influxdata.github.io/helm-charts
$ helm install influxdata/telegraf-ds
```

## Introduction

This chart bootstraps a `telegraf-ds` daemonset on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.4+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release influxdata/telegraf-ds
```

The command deploys a Telegraf daemonset on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section as well as the [values.yaml](/values.yaml) file lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The default configuration parameters are listed in `values.yaml`. To change the defaults, specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install --name my-release \
  --set config.outputs.influxdb.url=http://foo.bar:8086 \
    influxdata/telegraf-ds
```

The above command allows the chart to deploy by setting the InfluxDB URL for telegraf to write to.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install --name my-release -f values.yaml influxdata/telegraf-ds
```

## Telegraf Configuration

This chart deploys the following by default:

- `telegraf` (`telegraf-ds`) running in a daemonset with the following plugins enabled
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
