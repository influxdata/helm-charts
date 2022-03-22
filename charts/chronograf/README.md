# Chronograf Helm chart

[Chronograf](https://github.com/influxdata/chronograf) is an open-source web application used to visualize your monitoring data and easily create alerting and automation rules.

The Chronograf Helm chart uses the [Helm](https://helm.sh) package manager to bootstrap a Chronograf deployment and service on a [Kubernetes](http://kubernetes.io) cluster.

## Prerequisites

- Helm v2 or later
- Kubernetes 1.4+
- (Optional) PersistentVolume (PV) provisioner support in the underlying infrastructure

## Install the chart

1. Add the InfluxData Helm repository:

   ```bash
   helm repo add influxdata https://helm.influxdata.com/
   ```

2. Run the following command, providing a name for your Chronograf release:

   ```bash
   helm upgrade --install my-release influxdata/chronograf
   ```

   > **Tip**: `--install` can be shortened to `-i`.

   This command deploys Chronograf on the Kubernetes cluster using the default configuration. To find parameters you can configure during installation, see [Configure the chart](#configure-the-chart).

  > **Tip**: To view all Helm chart releases, run `helm list`.

## Uninstall the chart

To uninstall the `my-release` deployment, use the following command:

```bash
helm uninstall my-release
```

This command removes all Kubernetes components associated with the chart and deletes the release.

## Configure the chart

The following table lists configurable parameters, their descriptions, and their default values stored in `values.yaml`.

| Parameter                    | Description                                                                                               | Default                                     |
|:-----------------------------|:----------------------------------------------------------------------------------------------------------|:--------------------------------------------|
| `image.repository`           | image repository url                                                                                      | chronograf               |
| `image.tag`                  | controller container image tag                                                                            | 1.9.4                                       |
| `image.pullPolicy`           | controller container image pull policy                                                                    | IfNotPresent                                |
| `service.replicas`           | number of replicas for the specified service.type                                                         | 1                                           |
| `service.type`               | ClusterIP, NodePort, or LoadBalancer                                                                      | ClusterIP                                   |
| `persistence.enabled`        | Use a PVC to persist data                                                                                 | `false`                                     |
| `persistence.storageClass`   | Storage class of backing PVC                                                                              | `nil` (uses alpha storage class annotation) |
| `persistence.accessModes`    | Use volume as ReadOnly or ReadWrite                                                                       | `[ReadWriteOnce]`                           |
| `persistence.size`           | Size of data volume                                                                                       | `8Gi`                                       |
| `resources.requests.memory`  | Memory used for resource requests                                                                         | `256Mi`                                     |
| `resources.requests.cpu`     | CPU used for resource requests                                                                            | `0.1`                                       |
| `resources.limits.memory`    | Maximum memory that can be used for resource requests                                                     | `2Gi`                                       |
| `resources.limits.cpu`       | Maximum CPU that can be used for resource requests                                                        | `2`                                         |
| `ingress.enabled`            | Enable ingress controller resource                                                                        | false                                       |
| `ingress.hostname`           | Ingress resource hostnames                                                                                | chronograf.foobar.com                       |
| `ingress.tls`                | Ingress TLS configuration                                                                                 | false                                       |
| `ingress.annotations`        | Ingress annotations configuration                                                                         | null                                        |
| `oauth.enabled`              | Need to set to true to use any of the oauth options                                                       | false                                       |
| `oauth.token_secret`         | Used for JWT to support running multiple copies of Chronograf                                             | CHANGE_ME                                   |
| `oauth.github.enabled`       | Enable oauth github                                                                                       | false                                       |
| `oauth.github.client_id`     | oauth github client_id                                                                                    | CHANGE_ME                                   |
| `oauth.github.client_secret` | This is a comma separated list of GH organizations                                                        | CHANGE_ME                                   |
| `oauth.github.gh_orgs`       | oauth github                                                                                              | ""                                          |
| `oauth.google.enabled`       | Enable oauth google                                                                                       | false                                       |
| `oauth.google.client_id`     | oauth google                                                                                              | CHANGE_ME                                   |
| `oauth.google.client_secret` | This is a comma separated list of GH organizations                                                        | CHANGE_ME                                   |
| `oauth.google.public_url`    | oauth google                                                                                              | ""                                          |
| `oauth.google.domains`       | This is a comma separated list of Google Apps domains                                                     | ""                                          |
| `oauth.heroku.enabled`       | Enable oauth heroku                                                                                       | false                                       |
| `oauth.heroku.client_id`     | oauth heroku client_id                                                                                    | CHANGE_ME                                   |
| `oauth.heroku.client_secret` | This is a comma separated list of Heroku organizations                                                    | CHANGE_ME                                   |
| `oauth.heroku.gh_orgs`       | oauth github                                                                                              | ""                                          |
| `env`                        | Extra environment variables that will be passed onto deployment pods                                      | {}                                          |
| `envFromSecret`              | The name of a secret in the same kubernetes namespace which contain values to be added to the environment | {}                                          |
| `nodeSelector`               | Node labels for pod assignment                                                                            | {}                                          |
| `tolerations`                | Toleration labels for pod assignment                                                                      | []                                          |
| `affinity`                   | Affinity settings for pod assignment                                                                      | {}                                          |
| `influxdb.existingSecret`    | Name of an existing Secrect used to set the environment variables for the InfluxDB user and password. The expected keys in the secret are `influxdb-user` and `influxdb-password`. |

To configure the chart, do either of the following:

- Specify each parameter using the `--set key=value[,key=value]` argument to `helm upgrade --install`. For example, use the following command:

  ```bash
  helm upgrade --install my-release \
    --set ingress.enabled=true,ingress.hostname=chronograf.foobar.com \
      influxdata/chronograf
  ```

- Provide a YAML file that specifies parameter values while installing the chart. For example, use the following command:

  ```bash
  helm upgrade --install my-release -f values.yaml influxdata/chronograf
  ```

  > **Tip**: Use the default [values.yaml](values.yaml).

For information about running Chronograf in Docker, see the [full image documentation](https://quay.io/influxdb/chronograf).

## Persistence

The [Chronograf](https://quay.io/influxdb/chronograf) image stores data in the `/var/lib/chronograf` directory in the container.

The chart optionally mounts a [Persistent Volume](http://kubernetes.io/docs/user-guide/persistent-volumes/) at this location. The volume is created using dynamic volume provisioning.

## OAuth using Kubernetes Secret

Use environment variables to configure OAuth in Chronograf. For more information, see https://docs.influxdata.com/chronograf/latest/administration/managing-security.

The following example snippet shows a Kubernetes Secret that contains sensitive information (`GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`):

```
apiVersion: v1
kind: Secret
metadata:
  name: chronograf-google-env-secrets
  namespace: tick
type: Opaque
data:
    GOOGLE_CLIENT_ID: <BASE64_ENCODED_GOOGLE_CLIENT_ID>
    GOOGLE_CLIENT_SECRET: <BASE64_ENCODED_GOOGLE_CLIENT_SECRET>
```

With less sensitive information, such as `GOOGLE_DOMAINS` and `PUBLIC_URL`, use the chart's `envFromSecret` and `env` values. For example, include the following in a values file:

```
[...]
env:
  GOOGLE_DOMAINS: "yourdomain.com"
  PUBLIC_URL: "https://chronograf.yourdomain.com"
envFromSecret: chronograf-google-env-secrets
[...]
```

Check out our [Slack channel](https://www.influxdata.com/slack) for support and information.
