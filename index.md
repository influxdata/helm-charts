# InfluxData Helm Repository

![InfluxData](https://github.com/influxdata/helm-charts/raw/gh-pages/docs/assets/images/influxdata-logo.png)

## Add the InfluxData Helm repository

```bash
helm repo add influxdata https://helm.influxdata.com
```

## Install InfluxDB

```bash
helm upgrade -i influxdb influxdata/influxdb
```

For more details on installing InfluxDB please see the [chart's README](https://github.com/influxdata/helm-charts/tree/master/charts/influxdb).
