# Istio Installation with Telegraf-operator

> Warning: this is still a Work in Progress and breaking changes may occurr

This only runs with `istioctl` version > 1.5

## Steps:
1. install istio-operator
   ```shell
   istioctl operator init
   ```
2. install telegraf-operator
    ```shell
    helm repo add influxdata https://helm.influxdata.com
    helm install --namespace=telegraf-operator telegraf-operator influxdata/telegraf-operator
    ```
3. configure telegraf operator with `istio` class
    > This depends on which output system you desider for the istio metrics
4. `kubectl apply -f istio.yml`


## Reference:
- https://istio.io/docs/reference/config/istio.operator.v1alpha1/
