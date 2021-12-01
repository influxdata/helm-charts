# InfluxDB Enterprise

## Quick Start

```bash
helm repo add influxdata https://helm.influxdata.com/
helm upgrade --install influxdb influxdata/influxdb-enterprise --namespace monitoring
```

> **Tip**: `helm upgrade --install [RELEASE] [CHART] [FLAGS]` can be shortened : `helm upgrade -i [RELEASE] [CHART] [FLAGS]`

## Introduction

This chart bootstraps an InfluxDB Enterprise cluster, with a StatefulSet for both the meta and data nodes.

## Prerequisites

- Kubernetes 1.4+
- PV provisioner support in the underlying infrastructure (optional)

### Secrets

This chart requires the following secrets in order to function:

- License
- Shared Secret

Optionally, you can also provide secrets to enable:

- Authentication
- TLS

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

Since InfluxDB Enterprise can grab the license key from environment variable `INFLUXDB_ENTERPRISE_LICENSE_KEY`,
you can also leave `license` entry empty, save the key to a secret
and then refer to the secret in `envFromSecret`.

```yaml
license: {}
  # You can put your license key here for testing this chart out,
  # but we STRONGLY recommend using a license file stored in a secret
  # when you ship to production.
  # key: "your license key"
  # secret:
  #  name: license
  #  key: json

...

envFromSecret: influxdb-license
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

#### TLS (Optional)

If you want to configure TLS for your meta and/or data nodes, you must enable TLS inside the `values.yaml`. An example is below, but you'll need to replicate for the data nodes too:

```yaml
meta:
  https:
    enabled: true
```

If you want to use CertManager to provision the TLS certificates, you can add:

```yaml
meta:
  https:
    useCertManager: true
    insecure: true # This chart uses an untrusted CA, so we need to mark the keys as insecure
```

Otherwise, you need to provide a secret with the keys `tls.crt` and `tls.key`. An example exists inside the [example resources](./example-resources.yaml).

```yaml
meta:
  https:
    secret:
      name: my-tls-secret
    insecure: true # Only enable if your CA isn't trusted
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
