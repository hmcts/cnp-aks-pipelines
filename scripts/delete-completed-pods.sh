#!/usr/bin/env bash
set -e 
azureResourceGroup=$1
kubernetesCluster=$2
namespaces=( "${*:3}" )

az aks get-credentials --resource-group ${azureResourceGroup} --name ${kubernetesCluster} -a || echo "Cluster ${kubernetesCluster} not found in ${azureResourceGroup}"

for n in $namespaces; do
  kubectl get pod -n $n | grep Completed | awk '{print $1}' | xargs kubectl delete pod -n $n
done
