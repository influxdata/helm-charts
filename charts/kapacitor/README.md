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
| `image.tag` | Kapacitor image version | `1.6.4-alpine` |
| `image.pullPolicy` | Kapacitor image pull policy |  `IfNotPresent` |
| `strategy` | Kapacitor deployment strategy config |  |
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
| `influxURL` | InfluxDB url used to interact with Kapacitor | `http://influxdb-influxdb.tick:8086` |
| `existingSecret` | Name of an existing Secrect used to set the environment variables for the InfluxDB user and password. The expected keys in the secret are `influxdb-user` and `influxdb-password`. |
| `rbac.create` | Create and use RBAC resources | `true` |
| `rbac.namespaced` | Creates Role and Rolebinding instead of the default ClusterRole and ClusteRoleBindings for the Kapacitor instance  | `false` |
| `serviceAccount.annotations` | ServiceAccount annotations | `{}` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name to use, when empty will be set to created account if `serviceAccount.create` is set else to `default` |  |
| `sidecar.image` | Sidecar image | `kiwigrid/k8s-sidecar:0.1.116` |
| `sidecar.imagePullPolicy` | Sidecar image pull policy | `IfNotPresent` |
| `sidecar.resources` | Sidecar resources | `{}` |
| `sidecar.skipTlsVerify` | Set to true to skip tls verification for kube api calls | `nil` |
| `sidecar.sideload.enabled` | Enables the search for sideloads and adds/updates/deletes them in Kapacitor | `false` |
| `sidecar.sideload.label` | Label that configmaps with sideloads should have to be added | `kapacitor_sideload` |
| `sidecar.sideload.searchNamespace` | If specified, the sidecar will search for sideload configmaps inside this namespace. Otherwise the namespace in which the sidecar is running will be used. It's also possible to specify ALL to search in all namespaces | `nil` |
| `sidecar.sideload.folder` | Folder in the pod that should hold the collected sideloads. This path will be mounted. | `/var/lib/kapacitor/sideload` |
| `namespaceOverride` | Override the deployment namespace | `""` (`Release.Namespace`) |

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

## Sidecar for sideloads

If the parameter `sidecar.sideload.enabled` is set, a sidecar container is deployed in the Kapacitor
pod. This container watches all configmaps in the cluster and filters out the ones with
a label as defined in `sidecar.sideload.label`. The files defined in those configmaps are written
to a folder and can be accessed by TICKscripts. Changes to the configmaps are monitored and the files
are deleted/updated.

Example sideload config:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: kapacitor-sideload-influxdb-httpd-clienterror
  labels:
    kapacitor_sideload: "1"
data:
  influxdb-httpd-clienterror.yml: |
    [...]
```

---

Check out our [Slack channel](https://www.influxdata.com/slack) for support and information.
