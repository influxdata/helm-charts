# InfluxData Helm Charts

[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![](https://github.com/influxdata/helm-charts/workflows/Release%20Master/badge.svg?branch=master)](https://github.com/influxdata/helm-charts/actions)

This functionality is in beta and is subject to change. The code is provided as-is with no warranties. Beta features are not subject to the support SLA of official GA features.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add influxdata https://helm.influxdata.com/
```

You can then run `helm search repo influxdata` to see the charts.

## Configuration

The default configuration values for this chart are listed in `values.yaml`.

#### General

| Parameter | Description | Default |
|---|---|---|
| image.repository | Image repository url | influxdb |
| image.tag | Image tag | 1.7.6-alpine |
| image.pullPolicy | Image pull policy | IfNotPresent |
| image.pullSecrets | It will store the repository's credentials to pull image | nil |
| serviceAccount.create | It will create service account | true |
| serviceAccount.name | Service account name | "" |
| serviceAccount.annotations | Service account annotations | {} |
| livenessProbe | Health check for pod | {} |
| readinessProbe | Health check for pod | {} |
| startupProbe | Health check for pod | {} |
| service.type | Kubernetes service type | ClusterIP |
| persistence.enabled | Boolean to enable and disable persistance | true |
| persistence.storageClass | If set to "-", storageClassName: "", which disables dynamic provisioning. If undefined (the default) or set to null, no storageClassName spec is set, choosing the default provisioner.  (gp2 on AWS, standard on GKE, AWS & OpenStack |  |
| persistence.annotations | Annotations for volumeClaimTemplates | nil |
| persistence.accessMode | Access mode for the volume | ReadWriteOnce |
| persistence.size | Storage size | 8Gi |
| podAnnotations | Annotations for pod | {} |
| ingress.enabled | Boolean flag to enable or disable ingress | false |
| ingress.tls | Boolean to enable or disable tls for ingress. If enabled provide a secret in `ingress.secretName` containing TLS private key and certificate. | false |
| ingress.secretName | Kubernetes secret containing TLS private key and certificate. It is `only` required if `ingress.tls` is enabled. | nil |
| ingress.hostname | Hostname for the ingress | influxdb.foobar.com |
| annotations | ingress annotations | nil |
| schedulerName | Use an [alternate scheduler](https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/), e.g. "stork". | nil |
| nodeSelector | Node labels for pod assignment | {} |
| affinity | [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) for pod assignment |  {|
| tolerations | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/) for pod assignment | [] |
| env | environment variables for influxdb container | {} |
| config.reporting_disabled | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#reporting-disabled-false) | false |
| config.rpc | RPC address for backup and storage | {} |
| config.meta | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#meta) | {} |
| config.data | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#data) | {} |
| config.coordinator | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#coordinator) | {} |
| config.retention | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#retention) | {} |
| config.shard_precreation | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#shard-precreation) | {} |
| config.monitor | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#monitor) | {} |
| config.http | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#http) | {} |
| config.logging | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#logging) | {} |
| config.subscriber | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#subscriber) | {} |
| config.graphite | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#graphite) | {} |
| config.collectd | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#collectd) | {} |
| config.opentsdb | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#opentsdb) | {} |
| config.udp | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#udp) | {} |
| config.continous_queries | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#continuous-queries) | {} |
| config.tls | [Details](https://docs.influxdata.com/influxdb/v1.7/administration/config/#tls) | {} |
| initScripts.enabled | Boolean flag to enable and disable initscripts. If the container finds any files with the extensions .sh or .iql inside of the /docker-entrypoint-initdb.d folder, it will execute them. The order they are executed in is determined by the shell. This is usually alphabetical order. | false |
| initScripts.scripts | Init scripts | {} |
| backup.enabled | Boolean flag to enable and disable backups. Currently, it backups the data on `azure` and `gcs`. | false |
| backup.schedule | Cron time | `0 0 * * *`. It means create a backup everyday at `00:00`. |
| backup.annotations | Annotations for backup | {} |


## Contributing

We'd love to have you contribute! Please refer to our [contribution guidelines](CONTRIBUTING.md) for details.

## License

[MIT License](./LICENSE).
