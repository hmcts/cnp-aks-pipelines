#!/usr/bin/env bash

# Clean up old PR images from an ACR registry. The images selected for removal have a tag starting with 'pr-' 
# By default all such images are older than 5 days. 
# A repo filter can be added otherwise the entire registry is scanned.

set -e

# GNU date is needed to run this on a mac (e.g. gdate if installed using brew)
_date=date

# 5 days
repo_regex="${1:-.*}"
older_than=${2:-432000}
registry=hmctspublic
resource_group=rpe-acr-prod-rg

now_ts=$($_date '+%s') 
az acr repository list --name $registry --resource-group $resource_group -o tsv \
  | while read repo
do
  ! [[ "$repo" =~ $repo_regex ]] && echo "Skipping $repo as it does not match regex $repo_regex" && continue
  echo "Deleting old PR images for $repo"
  az acr repository show-manifests --name hmctspublic --repository "$repo"  \
    --query "[?not_null(tags[?starts_with(@, \`\"pr-\"\`)])]|sort_by([*], &timestamp)|[].[digest, timestamp]" -o tsv \
    | while read manifest
  do
    m_ts=$($_date -d `echo $manifest |cut -d' ' -f2` '+%s')
    if (( $now_ts - $m_ts > $older_than ))
    then
      echo "Deleting: $manifest"
      az acr repository delete --name $registry --image ${repo}@$(echo $manifest |cut -d' ' -f1) --yes
    fi
  done
done
