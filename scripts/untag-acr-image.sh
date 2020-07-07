#!/bin/bash

RELEASE_NAME=${1}
PRODUCT=${2}
CONTAINER_REGISTRY=${3}

component=$(echo ${RELEASE_NAME} | sed -e "s/^${PRODUCT}-//" -e 's/-pr-.*//')
repository="${PRODUCT}/${component}"
tag=$(echo ${RELEASE_NAME} | sed "s/.*-pr-/pr-/")

echo "Deleting $repository:$tag"

az acr repository show-tags -n ${CONTAINER_REGISTRY} --repository $repository --query "[?starts_with(@, '$tag')]" -o tsv \
| xargs -I% az acr repository untag -n ${CONTAINER_REGISTRY} --image "$repository:%"
echo "Deleted $repository:$tag"