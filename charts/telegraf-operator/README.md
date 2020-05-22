# Telegraf-operator

## Usage

```console
helm repo add influxdata https://helm.influxdata.com

helm install telegraf-operator influxdata/telegraf-operator

```

## Contributing & Developing

```shell
helm template --namespace=telegraf-operator telegraf-operator .
```

Test installation with Kind
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
