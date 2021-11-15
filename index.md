# InfluxData Helm Repository

![InfluxData](https://influxdata.github.io/branding/img/downloads/influxdata-logo--tagline--castle-alpha.png)

## Add the InfluxData Helm repository

```bash
helm repo add influxdata https://helm.influxdata.com
```

## Install InfluxDB

```bash
helm upgrade -i influxdb influxdata/influxdb
```

For more details on installing InfluxDB please see the [chart's README](https://github.com/influxdata/helm-charts/tree/master/charts/influxdb).
