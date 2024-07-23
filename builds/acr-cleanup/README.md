## ACR Cleanup
This pipeline is responsible for cleaning up the ACR repository by deleting images that are older than a certain number 
of days and that they match defined patterns in RegEx <repo-regEx:image-regEx> e.g. `"^labs/.*:.*", "^toffee.*:.*", "^plum.*:.*"`. 
The number of days is configurable in the pipeline.

The pipeline is scheduled to run every workday at 5:12 AM UTC.