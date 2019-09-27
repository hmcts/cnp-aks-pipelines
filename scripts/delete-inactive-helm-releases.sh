#!/usr/bin/env bash
set -e

for ns in $(echo "am bsp camunda ccd chart-tests cnp ctsc dg divorce em ethos evidence-mment family-public-law fees-pay financial-remedy ia idam immigration money-claims probate professional-applications rd rpe sscs"); do
  helmreleases=$(helm ls --namespace=${ns} --output=json | jq '.Releases')
  inactiveDays=${1:-7}

  for release in $(echo "${helmreleases}" | jq -r '.[] | @base64'); do
      lastUpdated=$(date -d "$(echo $release| base64 --decode | jq -r '.Updated')"  +%s)
      releaseName=$(echo $release| base64 --decode | jq -r '.Name')
      currenttime=$(date +%s)
      cutoff=$((inactiveDays*24*3600))
      if [ $((currenttime-lastUpdated)) -gt "$cutoff" ]
       then
         echo "Deleting Helm release ${releaseName} as it is inactive for more than ${inactiveDays} days"
         echo ${releaseName}
      fi
  done
done




