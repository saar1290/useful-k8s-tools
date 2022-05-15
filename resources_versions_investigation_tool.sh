#! /bin/bash

RED="\e[91m"
GREEN="\e[92m"
NONE="\e[0m"

resources="deployment daemonset replicaset secrets pods configmaps services ingresses endpoints issuer"
for r in $resources; do
    for d in $(kubectl get $r -A | awk '{print $1,$2}' | awk '(NR>1)'| tr ' ' ",");do 
        namespace=$(echo $d | cut -d , -f1)
        resource=$(echo $d | cut -d , -f2)
        api_version=$(kubectl get $r $resource -n $namespace -o json | jq -r '.apiVersion' | cut -d / -f2)
        resource_name=$(kubectl get $r $resource -n $namespace -o json | jq -r '.metadata.name')
        resource_namespace=$(kubectl get $r $resource -n $namespace -o json | jq -r '.metadata.namespace')
        if [[ $api_version == "v1beta1" ]]; then
            echo -e $RED"Resource $r/$resource_name in namespace $resource_namespace, have an API with pre-release version $api_version"$NONE
            echo ""
        elif [[ $api_version == "v1alpha1" ]]; then
            echo -e $RED"Resource $r/$resource_name in namespace $resource_namespace, have an API with experimental version $api_version"$NONE
            echo ""
        elif [[ $api_version == "v1" ]]; then
            echo -e $GREEN"Resource $r/$resource_name in namespace $resource_namespace, have an API stable version $api_version"$NONE
            echo ""
        fi
    done
done