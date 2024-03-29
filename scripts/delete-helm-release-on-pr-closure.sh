#!/usr/bin/env bash
azureResourceGroup=$1
kubernetesCluster=$2
namespace=$3
release_name=$4

az aks get-credentials --resource-group ${azureResourceGroup} --name ${kubernetesCluster} -a || echo "Cluster ${kubernetesCluster} not found in ${azureResourceGroup}"
if [ "$(helm get values --namespace "${namespace}" "${release_name}" 2>/dev/null)" ]; then
  helm delete --namespace ${namespace} ${release_name}
else
  echo "Chart ${release_name} not found."
fi
