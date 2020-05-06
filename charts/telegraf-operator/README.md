# Telegraf-operator

> Default installation expects cert-manager to be running in the cluster

## QuickStart

```console
helm repo add influxdata https://helm.influxdata.com

helm upgrade --install telegraf-operator influxdata/telegraf-operator

```

## Contributing and developing

```shell
helm template --namespace=telegraf-operator telegraf-operator .
```

Testing CI template
```shell
helm template --namespace=telegraf-operator --values=./ci/values.yaml telegraf-operator .
```
