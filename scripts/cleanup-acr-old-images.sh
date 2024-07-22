#!/usr/bin/env bash

# Clean up old images based on input parameters.

set -e

registry=${1:-hmctspublic}
repo_regex="${2:-.*}"
tag_filter="${3:-^ignore-.*}"
older_than="${4:-30d}"
keep_min_latest_num="${5:-5}"
repo_tag_filters="${6:-.*:-^ignore-.*}"


echo "$(TERM=xterm tput setaf 2)Cleaning up $registry, deleting ${tag_filter} images older than $older_than and keeping at least $keep_min_latest_num"

repo_tag_filters="^labs/ieuanb74:.*,^labs/jordankainos:.*"

IFS=',' read -r -a repo_tag_array <<< "$repo_tag_filters"

filter_args=""
for repo_tag_filter in "${repo_tag_array[@]}"; do
    filter_args="$filter_args --filter $repo_tag_filter"
done

echo "filter_args: $filter_args"

az acr run --registry $registry \
 --cmd "acr purge --registry \$RegistryName ${filter_args} --ago ${older_than} --keep ${keep_min_latest_num}  --untagged --concurrency 5" \
 --timeout 10800  /dev/null