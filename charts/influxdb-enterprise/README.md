# InfluxDB Enterprise

## QuickStart

```bash
helm repo add influxdata https://helm.influxdata.com/
helm upgrade --install influxdb influxdata/influxdb-enterprise --namespace monitoring
```

> **Tip**: `helm upgrade --install [RELEASE] [CHART] [FLAGS]` can be shortened : `helm upgrade -i [RELEASE] [CHART] [FLAGS]`

## Introduction

This chart bootstraps an InfluxDB Enterprise cluster, with a StatefulSet for both the Meta and Data nodes.

## Prerequisites

- Kubernetes 1.4+
- PV provisioner support in the underlying infrastructure (optional)

### Secrets

This chart REQUIRES some mandatory secrets in-order to function.

#### License

InfluxDB Enterprise requires a license. To provide the license, you can either store it in a secret or provide a string within your `values.yaml`. We recommend using a secret.

```yaml
license:
  # You can put your license key here for testing this chart out,
  # but we STRONGLY recommend using a license file stored in a secret
  # when you ship to production.
  # key: "your license key"
  secret:
    name: license
    key: json
```

#### Shared Secret

The meta cluster requires a shared internal secret to secure communication. This must be provided by specifying a secret name in the `values.yaml` file.

The Kubernetes Secret MUST contain a key called `secret` that is a randomly generated string.

Please see [example resources](./example-resources.yaml) to see what this looks like.

```yaml
meta:
  sharedSecret:
    secretName: shared-secret
```

#### Authentication (Optional)

If you want to configure authentication for your data nodes, you must provide the following within your `values.yaml`:

Please see [example resources](./example-resources.yaml) to see what this looks like.

```yaml
# A secret with keys "username" and "password" is required
bootstrap:
  auth:
    secretName: auth
```

#### DDL/DML (Optional)

If you wish to create databases or import data after installation, we've provided this DDL/DML hook. Your config map must contain the keys `ddl` and `dml`.

Please see [example resources](./example-resources.yaml) to see what this looks like.

```yaml
# A ConfigMap with keys "ddl" and "dml" is required
bootstrap:
  ddldml:
    configMap: ddl-dml
```

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm upgrade --install my-release influxdata/influxdb-enterprise
```

The command deploys InfluxDB Enterprise on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm uninstall my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.
