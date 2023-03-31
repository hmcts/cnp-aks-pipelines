#!/usr/bin/env bash

# Clean up old prod, aat and staging images from an ACR registry. The images selected for removal have a tag starting 
# with one of the following strings: 'prod-', 'aat-', 'staging-', 'demo-', 'ithc-', 'perftest-', 'sandbox-'
# All such images older than 30 days are deleted, but at least the most recent 6 images will always be kept.  
# A repo filter can be added otherwise the entire registry is scanned.

# Clean up old PR images from an ACR registry. The images selected for removal have a tag starting with 'pr-' 
# By default all such images are older than 5 days. 

set -e

repo_regex="${1:-.*}"
registry=${2:-hmctspublic}
older_than=30d
keep_min_latest_num=6
nonprod_older_than=5d

# az acr repository list --name "$registry" -o tsv \
#   | while read repo
# do
#   if ! [[ $repo =~ $repo_regex ]]; then
#     continue
#   fi

  echo "$(TERM=xterm tput setaf 2)Cleaning up $repo, deleting master images older than $older_than and keeping at least $keep_min_latest_num, pr images older than $pr_old_than"

  cat << EOF | az acr run --registry "$registry" -f - --timeout 10800 /dev/null
version: v1.1.0
steps:
  - cmd: acr purge --registry \$RegistryName --filter .*:^prod-.* --keep ${keep_min_latest_num} --ago ${older_than} --untagged --concurrency 5
    retries: 3
  - cmd: acr purge --registry \$RegistryName --filter .*:^aat.* --ago 0.5h --untagged --concurrency 5
    retries: 3
  - cmd: acr purge --registry \$RegistryName --filter .*:^staging.* --ago 0.5h --keep 1 --untagged --concurrency 5
    retries: 3
  - cmd: acr purge --registry \$RegistryName --filter .*:^demo.* --ago 0.5h --untagged --concurrency 5
    retries: 3
  - cmd: acr purge --registry \$RegistryName --filter .*:^ithc.* --ago 0.5h --untagged --concurrency 5
    retries: 3
  - cmd: acr purge --registry \$RegistryName --filter .*:^perftest.* --ago 0.5h --untagged --concurrency 5
    retries: 3
  - cmd: acr purge --registry \$RegistryName --filter .*:^sandbox-.* --keep ${keep_min_latest_num} --ago ${nonprod_older_than} --untagged --concurrency 5
    retries: 3
  - cmd: acr purge --registry \$RegistryName --filter .*:^pr-.* --ago ${nonprod_older_than} --untagged --concurrency 5
    retries: 3
EOF
  
# done
