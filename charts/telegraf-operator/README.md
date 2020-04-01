# Telegraf-operator

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


