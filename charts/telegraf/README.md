# Telegraf Helm chart

[Telegraf](https://github.com/influxdata/telegraf) is a plugin-driven server agent used for collecting and reporting metrics.

The Telegraf Helm chart uses the [Helm](https://helm.sh) package manager to bootstrap a Telegraf (`telegraf`) deployment on a [Kubernetes](http://kubernetes.io) cluster.

To see a list of available Telegraf plugins, see https://github.com/influxdata/telegraf/tree/master/plugins/.

## Prerequisites

- Helm v2 or later
- Kubernetes 1.4+ with beta APIs enabled

## Install the chart

1. Add the InfluxData Helm repository:

   ```bash
   helm repo add influxdata https://helm.influxdata.com/
   ```

2. Run the following command, providing a name for your Telegraf release:

   ```bash
   helm upgrade --install my-release influxdata/telegraf
   ```

   > **Tip**: `--install` can be shortened to `-i`.

   This command deploys Telegraf on the Kubernetes cluster using the default configuration. To find parameters you can configure during installation, see [Configure the chart](#configure-the-chart).

  > **Tip**: To view all Helm chart releases, run `helm list`.

## Uninstall the chart

To uninstall the `my-release` deployment, use the following command:

```bash
helm uninstall my-release
```

This command removes all Kubernetes components associated with the chart and deletes the release.

## Configure the chart

Plugins are configured as arrays of key/value dictionaries. Find configurable parameters, their descriptions, and their default values stored in `values.yaml`.

To configure the chart, do either of the following:

- Specify each parameter using the `--set key=value[,key=value]` argument to `helm upgrade --install`. For example:

  ```bash
  helm upgrade --install my-release \
    --set persistence.enabled=true \
      influxdata/telegraf
  ```

  This command enables persistence.

- Provide a YAML file that specifies the parameter values while installing the chart. For example, use the following command:

  ```bash
  helm upgrade --install my-release -f values.yaml influxdata/telegraf
  ```

  > **Tip**: Use the default [values.yaml](values.yaml).

### Use a custom Telegraf configuration

You can provide the Telegraf configuration as YAML-Value on the chart directly or by provisioning a separate ConfigMap.

### 1. Provide the Configuration as YAML directly

For example:

```yaml
# Content of example-values.yaml
config:
  agent:
    interval: "10s"
    round_interval: true
    metric_batch_size: 1000
    metric_buffer_limit: 10000
    collection_jitter: "0s"
    flush_interval: "10s"
    flush_jitter: "0s"
    precision: ""
    debug: false
    quiet: false
    logfile: ""
    hostname: "$HOSTNAME"
    omit_hostname: false
  processors:
    - enum:
        mapping:
          field: "status"
          dest: "status_code"
          value_mappings:
            healthy: 1
            problem: 2
            critical: 3
  outputs:
    - influxdb:
        urls:
          - "http://influxdb.monitoring.svc:8086"
        database: "telegraf"
  inputs:
    - statsd:
        service_address: ":8125"
        percentiles:
          - 50
          - 95
          - 99
        metric_separator: "_"
        allowed_pending_messages: 10000
        percentile_limit: 1000
```

```shell
helm upgrade --install my-release influxdata/telegraf -f example-values.yaml
```

> **Note:**
>
> The provided example uses the default telegraf configuration which are also provided in the `values.yaml` of this helm chart. You don't have to provide this by yourself. Just use this if you edit things by yourself.

### 2. Provide a ConfigMap with the TOML configuration within it

You can provide a TOML configuration file in a ConfigMap and let the helm chart use it:

```shell
kubectl create configmap telegraf-configuration \
	--from-file=telegraf.conf

helm upgrade --install my-release influxdata/telegraf --set existingConfigMapName=telegraf-configuration
```

> **Note:**
>
> This will overwrite the default Telegraf configuration completely. So you have to provide everything by yourself.
