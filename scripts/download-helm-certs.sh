#!/usr/bin/env bash

VAULT_NAME=$1
ENABLE_HELM_TLS=$2


function get_kv_secret {
 az keyvault secret download \
 --vault-name ${VAULT_NAME} \
 --encoding ascii \
 --name ${1} \
 --file ${2}
}

#download helm tls certs
if [[ ${ENABLE_HELM_TLS} == true ]]
then
    get_kv_secret helm-pki-tiller-cert tiller.cert.pem
    get_kv_secret helm-pki-tiller-key  tiller.key.pem
    get_kv_secret helm-pki-helm-cert   helm.cert.pem
    get_kv_secret helm-pki-helm-key    helm.key.pem
    get_kv_secret helm-pki-ca-cert     ca.cert.pem
fi