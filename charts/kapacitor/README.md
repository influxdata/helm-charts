# Kapacitor Helm chart

[Kapacitor](https://github.com/influxdata/kapacitor) is an open-source framework used for processing, monitoring, and alerting on time series data.

The Kapacitor Helm chart uses the [Helm](https://helm.sh) package manager to bootstrap a Kapacitor deployment and service on a [Kubernetes](http://kubernetes.io) cluster.

## Prerequisites

- Helm v2 or later
- Kubernetes 1.4+
- PersistentVolume (PV) provisioner support in the underlying infrastructure (optional)

## Install the chart

1. Add the InfluxData Helm repository:

   ```bash
   helm repo add influxdata https://helm.influxdata.com/
   ```

2. Run the following command, providing a name for your release:

   ```bash
   helm upgrade --install my-release influxdata/kapacitor
   ```

   > **Tip**: `--install` can be shortened to `-i`.

   This command deploys Kapacitor on the Kubernetes cluster using the default configuration. To find parameters you can configure during installation, see [Configure the chart](#configure-the-chart).

   > **Tip**: To view all Helm chart releases, run `helm list`.

## Uninstall the chart

To uninstall the `my-release` deployment, use the following command:

```bash
helm uninstall my-release
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Configure the chart

The following table lists configurable parameters, their descriptions, and their default values stored in `values.yaml`.

| Parameter               | Description                           | Default                                                    |
| ----------------------- | ----------------------------------    | ---------------------------------------------------------- |
| `image.repository` | image repository url | Kapacitor image | `kapacitor` |
| `image.tag` | Kapacitor image version | `1.5.2-alpine` |
| `image.pullPolicy` | Kapacitor image pull policy |  `IfNotPresent` |
| `service.type` | Kapacitor web service type  | `ClusterIP` |
| `persistence.enabled` | Enable Kapacitor persistence using Persistent Volume Claims | `false` |
| `persistence.storageClass` | Kapacitor Persistent Volume Storage Class | `default` |
| `persistence.accessMode` | Kapacitor Persistent Volume Access Mode | `ReadWriteOnce` |
| `persistence.size` | Kapacitor Persistent Volume Storage Size | `8Gi` |
| `persistence.existingClaim` | Kapacitor existing PVC name | `nil` |
| `resources.request.memory` | Kapacitor memory request | `256Mi` |
| `resources.request.cpu` | Kapacitor cpu request | `0.1` |
| `resources.limits.memory` | Kapacitor memory limit | `2Gi` |
| `resources.limits.cpu` | Kapacitor cpu limit | `2` |
| `envVars` | Environment variables to set initial Kapacitor configuration (https://hub.docker.com/_/kapacitor/) | `{}` |
| `influxURL` | InfluxDB url used to interact with Kapacitor (also can be set with ```envVars.KAPACITOR_INFLUXDB_0_URLS_0```) | `http://influxdb-influxdb.tick:8086` |
| `existingSecret` | Name of an existing Secrect used to set the environment variables for the InfluxDB user and password. The expected keys in the secret are `influxdb-user` and `influxdb-password`. |

To configure the chart, do either of the following:

- Specify each parameter using the `--set key=value[,key=value]` argument to `helm upgrade --install`. For example, use the following command:

  ```bash
  helm upgrade --install my-release \
  --set influxURL=http://myinflux.mytld:8086,persistence.enabled=true \
    influxdata/kapacitor
  ```
  
  This command enables persistence.

- Provide a YAML file that specifies parameter values while installing the chart. For example, use the following command:

  ```bash
  helm upgrade --install my-release -f values.yaml influxdata/kapacitor
  ```

  > **Tip**: Use the default [values.yaml](values.yaml).

For information about running Kapacitor in Docker, see the [full image documentation](https://hub.docker.com/_/kapacitor/).

## Persistence

The [Kapacitor](https://hub.docker.com/_/kapacitor/) image stores data in the `/var/lib/kapacitor` directory in the container.

The chart optionally mounts a [Persistent Volume](http://kubernetes.io/docs/user-guide/persistent-volumes/) at this location. The volume is created using dynamic volume provisioning.

Check out our [Slack channel](https://www.influxdata.com/slack) for support and information.
