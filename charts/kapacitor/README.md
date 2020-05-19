# Kapacitor

##  An Open-Source Time Series ETL and Alerting Engine

[Kapacitor](https://github.com/influxdata/kapacitor) is an open-source framework built by the folks over at [InfluxData](https://influxdata.com) and written in Go for processing, monitoring, and alerting on time series data

## QuickStart

```bash
helm repo add influxdata https://helm.influxdata.com/
helm upgrade --install kapacitor influxdata/kapacitor --namespace monitoring
```

> **Tip**: `helm upgrade --install [RELEASE] [CHART] [FLAGS]` can be shortened : `helm upgrade -i [RELEASE] [CHART] [FLAGS]`

## Introduction

This chart bootstraps A Kapacitor deployment and service on a Kubernetes cluster using the Helm Package manager.

## Prerequisites

- Kubernetes 1.4+
- PV provisioner support in the underlying infrastructure (optional)

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm upgrade --install my-release influxdata/kapacitor
```

The command deploys Kapacitor on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm uninstall my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the Kapacitor chart and their default values.

| Parameter               | Description                           | Default                                                    |
| ----------------------- | ----------------------------------    | ---------------------------------------------------------- |
| `image.repository` | Kapacitor image | `kapacitor` |
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
| `rbac.create` | Create and use RBAC resources | `true` |
| `rbac.namespaced` | Creates Role and Rolebinding instead of the default ClusterRole and ClusteRoleBindings for the Kapacitor instance  | `false` |
| `serviceAccount.annotations` | ServiceAccount annotations | `{}` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name to use, when empty will be set to created account if `serviceAccount.create` is set else to `default` | `` |
| `sidecar.image` | Sidecar image | `kiwigrid/k8s-sidecar:0.1.116` |
| `sidecar.imagePullPolicy` | Sidecar image pull policy | `IfNotPresent` |
| `sidecar.resources` | Sidecar resources | `{}` |
| `sidecar.skipTlsVerify` | Set to true to skip tls verification for kube api calls | `nil` |
| `sidecar.sideload.enabled` | Enables the search for sideloads and adds/updates/deletes them in Kapacitor | `false` |
| `sidecar.sideload.label` | Label that configmaps with sideloads should have to be added | `kapacitor_sideload` |
| `sidecar.sideload.searchNamespace` | If specified, the sidecar will search for sideload configmaps inside this namespace. Otherwise the namespace in which the sidecar is running will be used. It's also possible to specify ALL to search in all namespaces | `nil` |
| `sidecar.sideload.folder` | Folder in the pod that should hold the collected sideloads. This path will be mounted. | `/var/lib/kapacitor/sideload` |
| `namespaceOverride` | Override the deployment namespace | `""` (`Release.Namespace`) |

The configurable parameters of the Kapacitor chart and the default values are listed in `values.yaml`.

The [full image documentation](https://hub.docker.com/_/kapacitor/) contains more information about running Kapacitor in docker.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm upgrade --install my-release \
  --set influxURL=http://myinflux.mytld:8086,persistence.enabled=true \
    influxdata/kapacitor
```

The above command enables persistence and changes the size of the requested data volume to 200GB.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
helm upgrade --install my-release -f values.yaml influxdata/kapacitor
```

> **Tip**: You can use the default [values.yaml](values.yaml)

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