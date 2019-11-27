#!/usr/bin/env bash

# Clean up old prod, aat and staging images from an ACR registry. The images selected for removal have a tag starting 
# with one of the following strings: 'prod-', 'aat-', 'staging-' 
# All such images older than 30 days are deleted, but at least the most recent 6 images will always be kept.  
# A repo filter can be added otherwise the entire registry is scanned.

set -e

# GNU date is needed to run this on a mac (e.g. gdate if installed using brew)
_date=date

repo_regex="${1:-.*}"
registry=${2:-hmctspublic}
resource_group=${3:-rpe-acr-prod-rg}
older_than=2592000       # 30 days
keep_min_latest_num=6    # or at least 6 images if 30 days would leave fewer than 6 images


now_ts=$($_date '+%s') 
az acr repository list --name $registry --resource-group $resource_group -o tsv \
  | while read repo
do
  ! [[ "$repo" =~ $repo_regex ]] && echo "Skipping $repo as it does not match regex $repo_regex" && continue
  for _tag in prod aat staging
  do  
    echo "** Deleting old $_tag images for $repo"
    manifests=()
    while read -r manifest
    do 
      manifests+=("$manifest")
    done < <(az acr repository show-manifests --name hmctspublic --repository "$repo" --query "[?not_null(tags[?starts_with(@, \`\"${_tag}-\"\`)])]|sort_by([*], &timestamp)|[].[digest, timestamp]" -o tsv) 
    echo "Found ${#manifests[@]} $_tag images for ${repo}"
    count_removed=0
    if (( ${#manifests[@]} > $keep_min_latest_num ))
    then
      max_remove=$((${#manifests[@]} - $keep_min_latest_num - 1))
      for idx in $(seq 0 $max_remove)
      do
        m_ts=$($_date -d `echo ${manifests[idx]} |cut -d' ' -f2` '+%s')
        if (( $now_ts - $m_ts > $older_than ))
        then
          echo "Deleting: ${manifests[idx]}"
          m_sha=$(echo ${manifests[idx]} |cut -d' ' -f1)
          # Make sure we really have a manifest digest otherwise we might accidentally delete the entire repo! (never happened before :shifty-face:)
          if [[ $m_sha == sha256:* ]] 
          then
            az acr repository delete --name $registry --image ${repo}@${m_sha} --yes
          fi
          count_removed=$(($count_removed + 1))
        fi
      done
    fi
    echo "** Deleted $count_removed $_tag images for ${repo}"
  done
done
