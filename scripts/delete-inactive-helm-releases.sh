#!/usr/bin/env bash
set -e

for ns in $(echo "adoption am bsp bar camunda ccd chart-tests cnp coh ctsc dg divorce dm-store em ethos evidence-mment family-public-law fees-pay financial-remedy ia idam immigration money-claims pcq probate professional-applications rd reform-scan rpe sscs xui"); do
  helmreleases=$(helm ls --namespace=${ns} --output=json)
  inactiveDays=${1:-7}

  # Encoding and decoding to base64 is to handle spaces in updated field of helm ls command.
  for release in $(echo "${helmreleases}" | jq -r '.[] | @base64'); do
      fullDate=$(echo $release| base64 --decode | jq -r '.updated')
      # remove 'UTC' string, for some reason helm adds utc offset and timezone name which breaks parsing
      date=${fullDate%????}

    # Uses gnu date to convert to epoch millis, install gdate while running on mac.
      lastUpdated=$(date -d "${date}"  +%s)
      releaseName=$(echo $release| base64 --decode | jq -r '.name')
      currenttime=$(date +%s)
      cutoff=$((inactiveDays*24*3600))
      if [ $((currenttime-lastUpdated)) -gt "$cutoff" ]
       then
         echo "Deleting helm release ${releaseName} as it is inactive for more than ${inactiveDays} days. Last updated : ${date} "
         helm delete --namespace "${ns}" "${releaseName}"
#         Enable for debug if needed
#        else
#          echo "Skipping ${releaseName} as it is not inactive for ${inactiveDays}, Last updated: ${date}, cutoff=${cutoff}, result=$((currenttime-lastUpdated))"
      fi
  done
done




