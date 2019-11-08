#!/usr/bin/env bash

ENABLE_HELM_TLS=$1
CLUSTER_NAME=$2
WEBHOOK_URL=$3

if [[ ${ENABLE_HELM_TLS} == true ]]
then
    helm_tls_param="--tls --tls-verify --tls-ca-cert ca.cert.pem --tls-cert helm.cert.pem --tls-key helm.key.pem"
fi

sudo snap install yq

#get team config
curl -s https://raw.githubusercontent.com/hmcts/cnp-jenkins-config/master/team-config.yml > team-config.yaml
teamConfig=$(cat team-config.yaml)

declare -A namespaceMapping

#remove duplicates and prepare slack channel mapping.
for row in $(echo "${teamConfig}" | yq r -  -j | jq -r '.[] | @base64' ); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   namespace=$(_jq '.namespace')
   build_notices_channel=$(_jq '.slack.build_notices_channel')
   namespaceMapping[$namespace]=$build_notices_channel
done


#process failed releases
for ns in $(echo ${!namespaceMapping[*]}); do
  echo "Processing failed releases for namespace ${ns}"
  failedReleaseNames=""

  for release in $( helm ls --namespace=${ns} --failed --short --output=json $helm_tls_param | jq -r '.[] '); do
      echo "Found a failed release $release"
      failedReleaseNames+=$release" "
  done

  if [ ! -z "$failedReleaseNames" ]
  then
        echo "Sending notification to slack channel ${namespaceMapping[$ns]} for $failedReleaseNames"
        curl -s -X POST --data-urlencode "payload={\"channel\": \"${namespaceMapping[$ns]}\", \"username\": \"${CLUSTER_NAME}\", \"text\": \"Following Helm releases are in a *failed* state in your team name space *${ns}*  : *$failedReleaseNames*\", \"icon_emoji\": \":rotating_light:\"}" ${WEBHOOK_URL}
  fi

done

#process pending releases
for ns in $(echo ${!namespaceMapping[*]}); do
  echo "Processing pending releases for namespace ${ns}"
  pendingHelmreleases=$(helm ls --namespace=${ns} --pending --output=json $helm_tls_param | jq '.Releases')
  pendingReleaseNames=""
  # Encoding and decoding to base64 is to handle spaces in updated field of helm ls command.
  for release in $(echo "${pendingHelmreleases}" | jq -r '.[] | @base64'); do
    lastUpdated=$(date -d "$(echo $release| base64 --decode | jq -r '.Updated')"  +%s)
    releaseName=$(echo $release| base64 --decode | jq -r '.Name')
    currenttime=$(date +%s)
    cutoff=600 #600 seconds
    if [ $((currenttime-lastUpdated)) -gt "$cutoff" ]
    then
        echo "Found a release in pending state:  $releaseName"
        pendingReleaseNames+=$releaseName" "
        helm rollback $releaseName $helm_tls_param 0
    fi
  done

  if [ ! -z "$pendingReleaseNames" ]
  then
        echo "Sending notification to slack channel ${namespaceMapping[$ns]} for $pendingReleaseNames"
        curl -s -X POST --data-urlencode "payload={\"channel\": \"${namespaceMapping[$ns]}\", \"username\": \"${CLUSTER_NAME}\", \"text\": \"Following Helm releases are in a *pending* state in your team name space *${ns}*  and a rollback has been attempted: *$pendingReleaseNames*\", \"icon_emoji\": \":rotating_light:\"}" ${WEBHOOK_URL}
  fi

done
