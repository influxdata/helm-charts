# Telegraf-operator Helm chart

> Default installation expects `cert-manager` to be running in the cluster.

## Prerequisites

- Helm v2 or later
- Kubernetes 1.11+ with Beta APIs enabled

## Install the chart

1. Add the InfluxData Helm repository:

   ```bash
   helm repo add influxdata https://helm.influxdata.com/
   ```

2. Run the following command, providing a name for your release:

   ```bash
   helm upgrade --install my-release influxdata/telegraf-operator
   ```

   > **Tip**: `--install` can be shortened to `-i`.

   This command deploys Telegraf-operator on the Kubernetes cluster using the default configuration. To find parameters you can configure during installation, see [Configure the chart](#configure-the-chart).

   > **Tip**: To view all Helm chart releases, run `helm list`.

## Uninstall the chart

To uninstall the `my-release` deployment, use the following command:

```bash
helm uninstall my-release
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Configure the chart

Configurable parameters, their descriptions, and their default values are stored in `values.yaml`.

To configure the chart, do either of the following:

- Specify each parameter using the `--set key=value[,key=value]` argument to `helm upgrade --install`. For example, use the following command:

  ```bash
  helm upgrade --install my-release \
  --set persistence.enabled=true \
    influxdata/telegraf-operator
  ```
  
This command enables persistence.

- Provide a YAML file that specifies parameter values while installing the chart. For example, use the following command:

  ```bash
  helm upgrade --install my-release -f values.yaml influxdata/telegraf-operator
  ```

  > **Tip**: Use the default [values.yaml](values.yaml).

For information about running Telegraf-operator in Docker, see the [full image documentation](https://hub.docker.com/_/kapacitor/).

## Contribute to the chart

```shell
helm template --namespace=telegraf-operator telegraf-operator .
```

### Test installation with Kind

```shell
kind create cluster --name=telegraf-operator-test
kubectl config use-context kind-telegraf-operator-test
kubectl apply -f tests/influxdb.yml
helm install telegraf-operator .
kubectl apply -f tests/redis.yml
kind delete cluster --name=telegraf-operator-test
```

## Cert-manager integration 

For better security there is already an integration with cert-manger >0.13 that can be enabled but you have to provide your own instalation of cert-manager in the cluster
