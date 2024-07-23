#!/usr/bin/env bash

# Clean up old images based on input parameters.

set -e

registry=${1:-hmctspublic}
older_than="${2:-30d}"
keep_min_latest_num="${3:-5}"
repo_tag_filters="${4:-.*:-^ignore-.*}"

IFS=',' read -r -a repo_tag_array <<< "$repo_tag_filters"

filter_args=""
for repo_tag_filter in "${repo_tag_array[@]}"; do
    filter_args="$filter_args --filter $repo_tag_filter"
done
echo "$(TERM=xterm tput setaf 2)Cleaning up $registry, deleting [${filter_args}] images older than $older_than and keeping at least $keep_min_latest_num"

az acr run --registry "$registry" \
 --cmd "acr purge --registry \$RegistryName ${filter_args} --ago ${older_than} --keep ${keep_min_latest_num} --dry-run --untagged --concurrency 5" \
 --timeout 10800  /dev/null