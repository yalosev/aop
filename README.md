Not working example of json-patch remove (and also replace)

How to reproduce:
```bash
$ kubectl create ns addon-operator
$ kubectl apply -f manifests/
$ kubectl wait --for=condition=ready -n addon-operator -l app=addon-operator pod --timeout=120s
$ kubectl get cm pod-monitor-config -o jsonpath='{.data}'
# Output: {"pods.json":"["stub1","stub2","stub3"]\n"}

$ kubectl apply -f test/
$ kubectl wait --for=condition=ready -n default -l app=test pod --timeout=120s
$ kubectl get cm pod-monitor-config -o jsonpath='{.data}'
# Output: {"pods.json":"[\"test-848844fd9-zc257\"]\n"}

$ kubectl scale deployment test --replicas=2
$ kubectl get cm pod-monitor-config -o jsonpath='{.data}'
# Output: {"pods.json":"[\"test-848844fd9-zc257\", \"test-344545df4-gr24c\"]\n"}

$ kubectl scale deployment test --replicas=1
$ kubectl get cm pod-monitor-config -o jsonpath='{.data}'
# Output: {"pods.json":"[\"test-848844fd9-zc257\", \"test-344545df4-gr24c\"]\n"}
```