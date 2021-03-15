Lagging example of enabled-script

How to reproduce:
```bash
$ kubectl create ns addon-operator
$ kubectl apply -f manifests/
$ kubectl wait --for=condition=ready -n addon-operator -l app=addon-operator pod --timeout=120s
$ kubectl -n addon-operator logs -l app=addon-operator
# Output: 
# msg="COUNT: 0"
#
```
It seems ok here.

Now, lets change the addon-operator cm by adding more values
```bash
$ kubectl -n addon-operator patch --type=merge cm addon-operator -p '{"data":{"myModule":"{\"instances\": [\"a\",\"b\",\"c\",\"d\"]}"}}'
```
Logs seems like:
```bash
$ kubectl -n addon-operator logs -l app=addon-operator
# Output:
time="2021-03-15T09:25:07Z" level=info msg="INSTANCES: []" module=my-module operator.component=HandleConfigMap output=stdout
time="2021-03-15T09:25:07Z" level=info msg="COUNT: 0" module=my-module operator.component=HandleConfigMap output=stdout
```
and module is not enabled (obviously)


```bash
$ kubectl -n addon-operator patch --type=merge cm addon-operator -p '{"data":{"myModule":"{\"instances\": [\"a\",\"b\"]}"}}'
$ kubectl -n addon-operator logs -l app=addon-operator

# Output:
time="2021-03-15T09:25:33Z" level=info msg="INSTANCES: [\"a\",\"b\",\"c\",\"d\"]" module=my-module operator.component=HandleConfigMap output=stdout
time="2021-03-15T09:25:33Z" level=info msg="COUNT: 4" module=my-module operator.component=HandleConfigMap output=stdout
```

But `myModule` cm seems fine (up-to-date):
```bash
$ kubectl get cm my-module-config -o yaml
data:
  sample.json: |
    ["a","b"]
```

And every further iteration will have this lag. Seems like Values file is rendering after enabled-script.
But [documentation](https://github.com/flant/addon-operator/blob/master/VALUES.md#merged-values) says that it have to be render before.
