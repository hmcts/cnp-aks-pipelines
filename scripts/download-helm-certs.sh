#!/usr/bin/env bash

set -x

VAULT_NAME=$1
ENABLE_HELM_TLS=$2


function get_kv_secret {
 az keyvault secret download \
 --vault-name ${VAULT_NAME} \
 --encoding ascii \
 --name ${1} \
 --file ${2}
}

WEBHOOK_URL=$(az keyvault secret show --vault-name ${VAULT_NAME} --name slack-webhook-url --query value -o tsv)
echo "##vso[task.setvariable variable=WEBHOOK_URL;isOutput=true]$WEBHOOK_URL"

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

echo "##vso[task.setvariable variable=helm_tls_param;isOutput=true]$helm_tls_param"