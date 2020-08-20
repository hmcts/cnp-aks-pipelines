#!/usr/bin/env bash

# Clean up old prod, aat and staging images from an ACR registry. The images selected for removal have a tag starting 
# with one of the following strings: 'prod-', 'aat-', 'staging-' 
# All such images older than 30 days are deleted, but at least the most recent 6 images will always be kept.  
# A repo filter can be added otherwise the entire registry is scanned.

set -e

repo_regex="${1:-.*}"
registry=${2:-hmctspublic}
older_than=30d
keep_min_latest_num=6

az acr repository list --name "$registry" -o tsv \
  | while read repo
do
  if ! [[ $repo =~ $repo_regex ]]; then
    continue
  fi

  # ACR API doesn't respect the 'last' parameter on our base images when passing the sortby flag
  if [[ $repo =~ (^base/.*|^cmc/ccd-definition-importer$|^imported/.*|k8s-dns-node-cache-amd64|node-load|^rpe/auto-reply-urls$|rse/check|sscs/ccd-definition-importer-benefit|ignoretest/alpine|timj/auto-.*) ]]; then
    echo "$(TERM=xterm tput setaf 3)Skipping $repo as it's a base image"
    continue
  fi

  echo "$(TERM=xterm tput setaf 2)Cleaning up $repo, deleting images older than $older_than and keeping at least $keep_min_latest_num"

  cat << EOF | az acr run --registry "$registry" -f - --timeout 10800 /dev/null
version: v1.1.0
alias:
  values:
    forkedacr: "hmctspublic.azurecr.io/acr:fd0cf6"
steps:
  - cmd: \$forkedacr purge --registry \$RegistryName --filter $repo:^prod-.* --keep ${keep_min_latest_num} --ago ${older_than}
  - cmd: \$forkedacr purge --registry \$RegistryName --filter $repo:^aat-.* --keep ${keep_min_latest_num} --ago ${older_than}
  - cmd: \$forkedacr purge --registry \$RegistryName --filter $repo:^staging-.* --keep ${keep_min_latest_num} --ago ${older_than}
EOF
  
done
