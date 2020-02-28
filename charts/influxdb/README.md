# InfluxDB

##  An Open-Source Time Series Database

[InfluxDB](https://github.com/influxdata/influxdb) is an open source time series database built by the folks over at [InfluxData](https://influxdata.com) with no external dependencies. It's useful for recording metrics, events, and performing analytics.

## QuickStart

```bash
helm repo add influxdata https://helm.influxdata.com/
helm install my-release influxdata/influxdb --namespace monitoring
```

## Introduction

This chart bootstraps an InfluxDB statefulset and service on a Kubernetes cluster using the Helm Package manager.

## Prerequisites

- Kubernetes 1.4+
- PV provisioner support in the underlying infrastructure (optional)

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm install my-release influxdata/influxdb
```

The command deploys InfluxDB on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm delete my-release --purge
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The default configuration values for this chart are listed in `values.yaml`.

The [full image documentation](https://hub.docker.com/_/influxdb/) contains more information about running InfluxDB in docker.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm install my-release \
  --set persistence.enabled=true,persistence.size=200Gi \
    influxdata/influxdb
```

The above command enables persistence and changes the size of the requested data volume to 200GB.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
helm install my-release -f values.yaml influxdata/influxdb
```

> **Tip**: You can use the default [values.yaml](values.yaml)

### Enterprise
[InfluxDB Enterprise](https://www.influxdata.com/products/influxdb-enterprise/) is a hardened version of the open source core InfluxDB that includes additional closed source features designed for production workloads, featuring high availability and horizontal scaling. InfluxDB Enterprise features require a InfluxDB Enterprise license.

#### Configuration
To enable InfluxDB Enterprise, set the following keys and values in a values file provided to Helm.

| Key | Description | Recommended value |
| --- | --- | --- |
| `livenessProbe.initalDelaySeconds` | Used to allow enough time to join meta nodes to a cluster | `3600` |
| `image.tag` | Set to a `data` image. See https://hub.docker.com/_/influxdb for details | `data` |
| `service.ClusterIP` | Use a headless service for StatefulSets | `"None"` |
| `env.name[_HOSTNAME]` | Used to provide a unique `name.service` for InfluxDB. See [values.yaml]() for an example | `valueFrom.fieldRef.fieldPath: metadata.name` |
| `enterprise.enabled` | Create StatefulSets for use with `influx-data` and `influx-meta` images | `true` |
| `enterprise.licensekey` | License for InfluxDB Enterprise |  |
| `enterprise.clusterSize` | Replicas for `influx` StatefulSet | Dependent on license |
| `enterprise.meta.image.tag` | Set to an `meta` image. See https://hub.docker.com/_/influxdb for details | `meta` |
| `enterprise.meta.clusterSize` | Replicas for `influxdb-meta` StatefulSet. | `3` |
| `enterprise.meta.resources` | Resources requests and limits for meta `influxdb-meta` pods | See `values.yaml` |

#### Join pods to InfluxDB Enterprise cluster
Meta and data pods need to be joined together using the command `influxd-ctl` found on meta pods.
It is recommended you run `influxd-ctl` on one and only one meta pod, and to join meta pods together before data pods.
For each meta pod, run `influxd-ctl`. With default settings it should look something like this:
```shell script
kubectl exec influxdb-meta-0 influxd-ctl add-meta influxdb-meta-0.influxdb-meta:8091
```
From the same meta pod, for each data pod, run `influxd-ctl`. With default settings it should look something like this:
```shell script
kubectl exec influxdb-meta-0 influxd-ctl add-data influxdb-0.influxdb:8088
```
When using `influxd-ctl` be sure to use the appropriate DNS name for your pods, following the naming scheme of `pod.service`.
In the above examples, the pod names were `influxdb-meta-0` and `influxdb-0` respectively, and the service name was `influxdb`

## Persistence

The [InfluxDB](https://hub.docker.com/_/influxdb/) image stores data in the `/var/lib/influxdb` directory in the container.

If persistence is enabled, a [Persistent Volume](http://kubernetes.io/docs/user-guide/persistent-volumes/) associated with Statefulset will be provisioned. The volume is created using dynamic volume provisioning. In case of a disruption e.g. a node drain, kubernetes ensures that the same volume will be reatached to the Pod, preventing any data loss. Althought, when persistence is not enabled, InfluxDB data will be stored in an empty directory thus, in a Pod restart, data will be lost.

## Starting with authentication

In `values.yaml` change `.Values.config.http.auth_enabled` to `true`.

Influxdb requires also a user to be set in order for authentication to be enforced. See more details [here](https://docs.influxdata.com/influxdb/v1.2/query_language/authentication_and_authorization/#set-up-authentication).

To handle this setup on startup, a job can be enabled in `values.yaml` by setting `.Values.setDefaultUser.enabled` to `true`.

Make sure to uncomment or configure the job settings after enabling it. If a password is not set, a random password will be generated.

Alternatively, if `.Values.setDefaultUser.user.existingSecret` is set the user and password are obtained from an existing Secret, the expected keys are `influxdb-user` and `influxdb-password`. Use this variable  if you need to check in the `values.yaml` in a repository to avoid exposing your secrets.

## Backing up and restoring

Before proceeding, please read [Backing up and restoring in InfluxDB OSS](https://docs.influxdata.com/influxdb/v1.7/administration/backup_and_restore/). While the chart offers backups by means of the [`backup-cronjob`](./templates/backup-cronjob.yaml), restores do not fall under the chart's scope today but can be achieved by one-off kubernetes jobs.

### Backups

When enabled, the[`backup-cronjob`](./templates/backup-cronjob.yaml) runs on the configured schedule. One can create a job from the backup cronjob on demand as follows:

```sh
kubectl create job --from=cronjobs/influxdb-backup influx-backup-$(date +%Y%m%d%H%M%S)
```

### Restores

It is up to the end user to configure their own one-off restore jobs. Below is just an example, which assumes that the backups are stored in GCS and that all dbs in the backup already exist and should be restored. It is to be used as a reference only; configure the init-container and the command and of the `influxdb-restore` container as well as both containers' resources to suit your needs.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: influxdb-restore-
  namespace: monitoring
spec:
  template:
    spec:
      volumes:
        - name: backup
          emptyDir: {}
      serviceAccountName: influxdb
      initContainers:
        - name: init-gsutil-cp
          image: google/cloud-sdk:alpine
          command:
            - /bin/sh
          args:
            - "-c"
            - |
              gsutil -m cp -r gs://<PATH TO BACKUP FOLDER>/* /backup
          volumeMounts:
            - name: backup
              mountPath: /backup
          resources:
            requests:
              cpu: 1
              memory: 4Gi
            limits:
              cpu: 2
              memory: 8Gi
      containers:
        - name: influxdb-restore
          image: influxdb:1.7-alpine
          volumeMounts:
            - name: backup
              mountPath: /backup
          command:
            - /bin/sh
          args:
            - "-c"
            - |
              #!/bin/sh
              INFLUXDB_HOST=influxdb.monitoring.svc
              for db in $(influx -host $INFLUXDB_HOST -execute 'SHOW DATABASES' | tail -n +5); do
                influxd restore -host $INFLUXDB_HOST:8088 -portable -db "$db" -newdb "$db"_bak /backup
              done
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
      restartPolicy: OnFailure
```

At which point the data from the new `<db name>_bak` dbs would have to be side loaded into the original dbs.
Please see [InfluxDB documentation for more restore examples](https://docs.influxdata.com/influxdb/v1.7/administration/backup_and_restore/#restore-examples).

## Upgrading

### From < 1.0.0 To >= 1.0.0

Values `.Values.config.bind_address` and `.Values.exposeRpc` no longer exist. They have been replaced with `.Values.config.rpc.bind_address` and `.Values.config.rpc.enabled` respectively. Please adjust your values file accordingly.

### From < 1.5.0 to >= 2.0.0

The Kubernetes API change to support 1.160 may not be backwards compatible and may require the chart to be uninstalled in order to upgrade.  See [this issue](https://github.com/helm/helm/issues/6583) for some background.

### From < 3.0.0 to >= 3.0.0

Since version 3.0.0 this chart uses a StatefulSet instead of a Deployment. As part of this update the existing persistent volume (and all data) is deleted and a new one is created. Make sure to backup and restore the data manually.

### From < 4.0.0 to >= 4.0.0

Labels are changed to those in accordance with [kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/\#labels). This change also removes the ability to configure clusterIP value as to avoid `Error: UPGRADE FAILED: failed to replace object: Service "my-influxdb" is invalid: spec.clusterIP: Invalid value: "": field is immutable` type errors. For more info on this error and why it should be avoided at all costs, please see [this github issue](https://github.com/helm/helm/issues/6378#issuecomment-582764215).

Due to the significance of the changes. The recommended approach is to uninstall and reinstall the chart (the PVC *should* not be deleted during this process, but it is highly recommended to backup your data before).
