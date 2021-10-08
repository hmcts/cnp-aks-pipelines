#!/usr/bin/env bash
set -e
azureSubscription=$1
azureResourceGroup=$2
kubernetesCluster=$3
namespaces=( "${*:4}" )

az account set -s ${azureSubscription}
error=$(az aks get-credentials --resource-group ${azureResourceGroup} --name ${kubernetesCluster} --subscription ${azureSubscription} -a 2>&1 1>/dev/null || echo "")

if [[ $error == ERROR* ]]
then
  echo "error = ${error}"
else
  for n in $namespaces; do
    pods=$(kubectl get pod -n $n 2>&1 | grep Completed | awk '{print $1}')
    if [ -z "${pods}" ]
    then
      echo "No Completed pods to delete"
    else
      deleteError=$(echo $pods | xargs kubectl delete pod -n $n 2>&1)
      echo $deleteError
    fi
  done
fi
