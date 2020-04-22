# Telegraf-operator

> Default installation expects cert-manager to be running in the cluster

## Usage

```console
helm repo add influxdata https://helm.influxdata.com

helm install telegraf-operator influxdata/telegraf-operator

```

## Contributing

```
helm dependency update
helm template telegraf-operator .
```

## Developing

```
helm template telegraf-operator . > test.yml
code --diff test.yml stub.yml
```
