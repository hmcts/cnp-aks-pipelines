#!/usr/bin/env bash

# Clean up old images based on input parameters.

set -e

registry=${1:-hmctspublic}
repo_regex="${2:-.*}"
tag_filter="${3:-^ignore-.*}"
older_than="${4:-30d}"
keep_min_latest_num="${5:-5}"


echo "$(TERM=xterm tput setaf 2)Cleaning up $registry, deleting ${tag_filter} images older than $older_than and keeping at least $keep_min_latest_num"

az acr run --registry $registry --cmd "acr purge --registry \$RegistryName --filter ${repo_regex}:${tag_filter} --ago ${older_than} --keep ${keep_min_latest_num}  --untagged --concurrency 5" --timeout 10800  /dev/null