#!/bin/bash

set -ex

RELEASE_NAME=${1}
PRODUCT=${2}

component=$(echo ${RELEASE_NAME} | sed -e "s/^${PRODUCT}-//" -e 's/-pr-.*//')
REPOSITORY="${PRODUCT}/${component}"
TAG=$(echo ${RELEASE_NAME} | sed "s/.*-pr-/pr-/")

pwd
ls
cd cnp-flux-config

for REPO_FILE in $(grep -Elr "kind: ImageRepository"  apps/ | xargs grep -El "$REPOSITORY" ); do

  if [ $(yq eval '.kind' $REPO_FILE) != "ImageRepository" ]
  then
    continue # safety to make sure it doesn't find these any scripts etc
  fi

  IMAGE_REPOSITORY=$(yq eval '.metadata.name' $REPO_FILE)

  if [[ -z $IMAGE_REPOSITORY ]]
  then
    echo " IMAGE_REPOSITORY should not be null, exiting here to avoid issues"
    exit 1
  fi

  for POLICY_FILE in $(grep -Elr "kind: ImagePolicy"  apps/ | xargs grep -El "$IMAGE_REPOSITORY" | xargs grep -El "$TAG" ); do

    if [ $(yq eval '.kind' $POLICY_FILE) != "ImagePolicy" ]
      then
        continue # safety to make sure it doesn't find these any scripts etc
    fi

    echo "Removing $TAG image policy from $POLICY_FILE"

    yq -i 'delpaths([["metadata", "annotations"], ["spec", "filterTags"], ["spec", "policy"]])' $POLICY_FILE

    if [[ -n $(git status -s) ]]
    then
      git config --global user.email github-platform-operations@HMCTS.NET & git config --global user.name "hmcts-platform-operations"
      git checkout -b testmychange
      git add .
      git commit -m "Removing $TAG image policy from $POLICY_FILE"
      git -c http.extraheader="AUTHORIZATION: bearer $(System.AccessToken)" push --set-upstream origin testmychange

    fi

  done

done