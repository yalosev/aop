#!/usr/bin/env bash

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
  - name: OnCreateDeletePod
    apiVersion: v1
    kind: Pod
    executeHookOnEvent:
      - Added
      - Deleted
    jqFilter: ".metadata"
    keepFullObjectsInMemory: false
    namespace:
      nameSelector:
        matchNames: ["default"]
EOF
exit $?;
fi


type=$(jq -r '.[0].type' $BINDING_CONTEXT_PATH)
if [[ $type == "Synchronization" ]] ; then
  objects=$(jq -r ".[0].objects" $BINDING_CONTEXT_PATH)
  PODNAMES=$(echo $objects | jq -r "[.[].filterResult.name]")

  cat > $VALUES_JSON_PATCH_PATH <<EOF
[{"op":"add", "path":"/podMonitor/pods", "value":$PODNAMES}]
EOF
  exit 0
fi


ARRAY_COUNT=$(jq -r '. | length-1' $BINDING_CONTEXT_PATH)
for IND in `seq 0 $ARRAY_COUNT`; do
  bindingName=$(jq -r ".[$IND].binding" $BINDING_CONTEXT_PATH)
  podName=$(jq -r ".[$IND].filterResult.name" $BINDING_CONTEXT_PATH)
  resourceEvent=$(jq -r ".[$IND].watchEvent" $BINDING_CONTEXT_PATH)

  arrayIndex=$(jq ".podMonitor.pods | map(. == \"$podName\") | index(true)" ${VALUES_PATH})
  if [[ -z $arrayIndex ]] || [[ "$arrayIndex" == "null" ]]; then # обожаю баш, null == 0 !
    arrayIndex=-1
  fi


  if [[ $bindingName == "OnCreateDeletePod" ]] ; then
      if [[ ${resourceEvent} == "Added" ]]; then
          echo "Pod ${podName}: ${arrayIndex} has been added"
          if [[ "$arrayIndex" -ge "0" ]]; then
              echo "Pod ${podName} already exists. Skipping"
              # seems like replace also doesnt work...
          else
              echo "JSON PATCH: [{\"op\":\"add\", \"path\":\"/podMonitor/pods/-\", \"value\":\"$podName\"}]"
              echo "[{\"op\":\"add\", \"path\":\"/podMonitor/pods/-\", \"value\":\"$podName\"}]" > ${VALUES_JSON_PATCH_PATH}
          fi
      elif [[ ${resourceEvent} == "Deleted" ]]; then
          echo "Pod ${podName}: ${arrayIndex} has been deleted"
          if [[ "$arrayIndex" -ge "0" ]]; then
            echo "JSON PATCH: [{ \"op\": \"remove\", \"path\": \"/podMonitor/pods/${arrayIndex}\" }]"
            echo "[{ \"op\": \"remove\", \"path\": \"/podMonitor/pods/${arrayIndex}\" }]" > ${VALUES_JSON_PATCH_PATH}
          fi
      fi
  else
    echo "Unknown binding: $bindingName";
    exit 1;
  fi
done