#! /bin/bash

GREEN="\e[92m"
NONE="\e[0m"

read -p "Enter the ports to path on controller pod (with spaces)---> " ports

for port in $ports; do
    echo -e $GREEN"Adding port $port to controller pod"$NONE
    kubectl patch deployments.apps -n nginx-ingress-controller nginx-ingress-controller-ingress-nginx-controller --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"containerPort": '$port', "name": "'$port'-tcp", "protocol": "TCP"}}]'
done