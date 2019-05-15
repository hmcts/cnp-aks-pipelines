#!/usr/bin/env bash
# setup env with ENVIRONMENT with the env name /path in flux-config
# Change to corresponding env path
echo "cloning flux config"
mkdir cnp-flux-config
git clone https://github.com/hmcts/cnp-flux-config.git
git checkout master
cd cnp-flux-config/k8s/${ENVIRONMENT}

#Create temporary directory
mkdir tmp

echo "fetching public cert for kubeseal "
#fetch kubeseal cert
kubeseal --fetch-cert --controller-namespace=admin --controller-name=sealed-secrets > pub-cert.pem

#git status after changes
echo "git status to checking if cert has changed"
git status

#Regenerate Sealed secrets from existing sealed secrets

echo "Regenerating sealed secrets from existing secret"

for i in $(kubectl get secret -A -o=jsonpath='{range .items[?(@.metadata.ownerReferences[0].kind=="SealedSecret")]}{.metadata.namespace}{":"}{.metadata.name}{" "}{end}'); do
NAMESPACE=${i%:*}
SECRET=${i##*:}
kubectl get secret -n ${NAMESPACE} ${SECRET} -o json > tmp/${NAMESPACE}-${SECRET}-secret.json
kubeseal --format=yaml --cert=pub-cert.pem <tmp/${NAMESPACE}-${SECRET}-secret.json> ${NAMESPACE}/${SECRET}.yaml
done

#delete tmp folder
rm -rf tmp

#git commit files
echo "Attempting to commit files to git"
git add .

#git status after changes
echo "checking git status before commiting"
git status

git commit -m "Regenerating Sealed secrets with latest certificate for $(environment)"
git push