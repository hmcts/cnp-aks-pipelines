#!/usr/bin/env bash
azureResourceGroup=${1:cft-preview-00-rg}
kubernetesCluster=${2:cft-preview-00-aks}
defaultInactiveDays=${3:-3}
declare -A inactiveDaysOverride=(["civil"]=1) # Value should be less than defaultInactiveDays defined above

az aks get-credentials --resource-group ${azureResourceGroup} --name ${kubernetesCluster} -a || echo "Cluster ${kubernetesCluster} not found in ${azureResourceGroup}"

#get team config
curl -s https://raw.githubusercontent.com/hmcts/cnp-jenkins-config/master/team-config.yml > team-config.yaml
teamConfig=$(cat team-config.yaml)
declare -A namespaceMapping
#remove duplicates and prepare namespace mapping.
for row in $(echo "${teamConfig}" | yq e -  -j | jq -r '.[] | @base64' ); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   namespace=$(_jq '.namespace')
   # whitelist namespace being deleted accidentally.
   if [ $namespace != "admin" ]
    then
     namespaceMapping[$namespace]=1
   fi
done

for ns in $(echo ${!namespaceMapping[*]}); do
  helmreleases=$(helm ls --namespace=${ns} --output=json)

  # Encoding and decoding to base64 is to handle spaces in updated field of helm ls command.
  for release in $(echo "${helmreleases}" | jq -r '.[] | @base64'); do
      fullDate=$(echo $release| base64 --decode | jq -r '.updated')
      # remove 'UTC' string, for some reason helm adds utc offset and timezone name which breaks parsing
      date=${fullDate%????}

    # Uses gnu date to convert to epoch millis, install gdate while running on mac.
      lastUpdated=$(date -d "${date}"  +%s)
      releaseName=$(echo $release| base64 --decode | jq -r '.name')
      currenttime=$(date +%s)
      if [ ${inactiveDaysOverride[$ns]} ]
      then
        cutoffDays=${inactiveDaysOverride[$ns]}
      else
        cutoffDays=${defaultInactiveDays}
      fi
      cutoff=$((cutoffDays*24*3600))
      
      #Test inactive helm releases
      if [ $((currenttime-lastUpdated)) -gt "$cutoff" ]
       then
         echo "List helm release ${releaseName} as it is inactive for more than ${cutoffDays} days. Last updated : ${date} "
      if

      #if [[ $((currenttime-lastUpdated)) -gt "$cutoff" && ${releaseName} = "*-pr-*" ]]
       #then
         #echo "Deleting helm release ${releaseName} as it is inactive for more than ${cutoffDays} days. Last updated : ${date} "
         #helm delete --namespace "${ns}" "${releaseName}"
#         Enable for debug if needed
#        else
#          echo "Skipping ${releaseName} as it is not inactive for ${cutoffDays}, Last updated: ${date}, cutoff=${cutoff}, result=$((currenttime-lastUpdated))"
      #fi
  done
done




