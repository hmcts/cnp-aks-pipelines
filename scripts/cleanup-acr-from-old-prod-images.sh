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

  echo "$(TERM=xterm tput setaf 2)Cleaning up $repo, deleting images older than $older_than and keeping at least $keep_min_latest_num"

  cat << EOF | az acr run --registry "$registry" -f - --timeout 10800 /dev/null
version: v1.1.0
steps:
  - cmd: acr purge --registry \$RegistryName --filter $repo:^prod-.* --keep ${keep_min_latest_num} --ago ${older_than} --untagged
  - cmd: acr purge --registry \$RegistryName --filter $repo:^aat-.* --keep ${keep_min_latest_num} --ago ${older_than} --untagged
  - cmd: acr purge --registry \$RegistryName --filter $repo:^staging-.* --keep ${keep_min_latest_num} --ago ${older_than} --untagged
EOF
  
done
