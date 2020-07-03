#!/usr/bin/env bash
set -e 
azureResourceGroup=$1
kubernetesCluster=$2

az aks get-credentials --resource-group ${azureResourceGroup} --name ${kubernetesCluster} -a || echo "Cluster ${kubernetesCluster} not found in ${azureResourceGroup}"

helmreleases=$(helm ls --failed --all-namespaces --output=json)

# Encoding and decoding to base64 is to handle spaces in updated field of helm ls command.
for release in $(echo "${helmreleases}" | jq -r '.[] | @base64'); do
  releaseName=$(echo $release| base64 --decode | jq -r '.name')
  namespace=$(echo $release| base64 --decode | jq -r '.namespace')
  helm delete --namespace "${namespace}" "${releaseName}"
done