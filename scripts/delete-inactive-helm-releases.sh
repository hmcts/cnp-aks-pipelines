#!/usr/bin/env bash
set -e

for ns in $(echo "am bsp camunda ccd chart-tests cnp ctsc dg divorce em ethos evidence-mment family-public-law fees-pay financial-remedy ia idam immigration money-claims probate professional-applications rd rpe sscs"); do
  helmreleases=$(helm ls --namespace=${ns} --output=json | jq '.Releases')
  inactiveDays=${1:-7}

  #Encoding and decoding to base64 is to handle spaces in updated field of helm ls command.
  for release in $(echo "${helmreleases}" | jq -r '.[] | @base64'); do
    #uses gdate to convert to epoch millis. Install gdate while running on mac.
      lastUpdated=$(date -d "$(echo $release| base64 --decode | jq -r '.Updated')"  +%s)
      releaseName=$(echo $release| base64 --decode | jq -r '.Name')
      currenttime=$(date +%s)
      cutoff=$((inactiveDays*24*3600))
      if [ $((currenttime-lastUpdated)) -gt "$cutoff" ]
       then
         echo "Deleting Helm release ${releaseName} as it is inactive for more than ${inactiveDays} days. LastUpdated :  $(echo "$release"| base64 --decode | jq -r '.Updated') "
         helm delete --purge "${releaseName}"
      fi
  done
done




