#!/usr/bin/env bash

VAULT_NAME=$1
ENABLE_HELM_TLS=$2
CLUSTER_NAME=$3

sudo snap install yq

function get_kv_secret {
 az keyvault secret download \
 --vault-name ${VAULT_NAME} \
 --encoding ascii \
 --name ${1} \
 --file ${2}
}

WEBHOOK_URL=$(az keyvault secret show --vault-name ${VAULT_NAME} --name slack-webhook-url --query value -o tsv)
#download helm tls certs
if [[ ${ENABLE_HELM_TLS} == true ]]
then
    get_kv_secret helm-pki-tiller-cert tiller.cert.pem
    get_kv_secret helm-pki-tiller-key  tiller.key.pem
    get_kv_secret helm-pki-helm-cert   helm.cert.pem
    get_kv_secret helm-pki-helm-key    helm.key.pem
    get_kv_secret helm-pki-ca-cert     ca.cert.pem
    helm_tls_param="--tls --tls-verify --tls-ca-cert ca.cert.pem --tls-cert helm.cert.pem --tls-key helm.key.pem"
fi

function get_kv_secret {
 az keyvault secret download \
 --vault-name ${VAULT_NAME} \
 --encoding ascii \
 --name ${1} \
 --file ${2}
}

#get team config
curl -s https://raw.githubusercontent.com/hmcts/cnp-jenkins-config/master/team-config.yml > team-config.yaml
teamConfig=$(cat team-config.yaml)

declare -A namespaceMapping

#remove duplicates and prepare slack channel mapping.
for row in $(echo "${teamConfig}" | yq r -  -j | jq .[] | base64 ); do
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
        #curl -X POST --data-urlencode 'payload={"channel": "${namespaceMapping[$ns]}", "username": "${CLUSTER_NAME}", "text": "Helm releases are in a failed state: $failedReleaseNames", "icon_emoji": ":rotating_light:"}' $(WEBHOOK_URL)
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
        #helm rollback $releaseName $helm_tls_param 0
    fi
  done

  if [ ! -z "$pendingReleaseNames" ]
  then
        echo "Sending notification to slack channel ${namespaceMapping[$ns]} for $pendingReleaseNames"
        #curl -X POST --data-urlencode 'payload={"channel": "${namespaceMapping[$ns]}", "username": "${CLUSTER_NAME}", "text": "Helm releases are in a pending state and a rollback has been attempted: $pendingReleaseNames", "icon_emoji": ":rotating_light:"}' $(WEBHOOK_URL)
  fi

done