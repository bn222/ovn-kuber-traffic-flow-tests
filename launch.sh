#!/bin/bash

# source the functions in labels.sh
. labels.sh

FT_LABEL_ACTION=add
FT_SMARTNIC_SERVER=false
FT_NORMAL_CLIENT=false
FT_SMARTNIC_CLIENT=false
manage_labels

if [ "$FT_SMARTNIC_SERVER" == true ] || [ "$FT_SMARTNIC_CLIENT" == true ]; then
  kubectl create -f netAttachDef-smartNic.yaml
fi

# Create normal Pods and Service
kubectl apply -f svc-nodePort.yaml

if [ "$FT_SMARTNIC_SERVER" == true ]; then
  kubectl apply -f server-pod-v4-smartNic.yaml
else
  kubectl apply -f server-pod-v4.yaml
fi

if [ "$FT_NORMAL_CLIENT" == true ]; then
  kubectl apply -f client-daemonSet.yaml
fi
if [ "$FT_SMARTNIC_CLIENT" == true ]; then
  kubectl apply -f client-daemonSet-smartNic.yaml
fi

# Create HOST backed Pods and Service
kubectl apply -f svc-nodePort-host.yaml
kubectl apply -f server-pod-v4-host.yaml
kubectl apply -f client-daemonSet-host.yaml