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
4. Create secret statsd metrics shipping
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
        name: monitor
        namespace: istio-system
    stringData:
        ENV: testing
        MONITOR_BUCKET: istio
        MONITOR_HOST_V2: https://us-west-2-1.aws.cloud2.influxdata.com/
        MONITOR_ORG: my-best-organization-in-cloud2
        MONITOR_TOKEN: xxxxxxxxxxxxxx
    type: Opaque
    ```
5. `kubectl apply -f statsd.yml`
6. `kubectl apply -f istio.yml`


## Reference:
- https://istio.io/docs/reference/config/istio.operator.v1alpha1/
- https://istio.io/docs/ops/deployment/requirements/
