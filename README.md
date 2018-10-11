# AKS Cluster Pipelines

## Introduction 
Collection of pipelines that automate the recreation of the AKS clusters used for continuous integration.
In general, the pipelines do the following:
* Fetch required configuration from various sources (keyvault, az cli queries)
* destroy and recreate the existing AKS cluster
* configure RBAC roles
* install required applications using Helm, such as Service Catalog and Open Service Broker for Azure

The pipelines do __NOT__ create the required network infrastructure, it must already be present.

## AKS Cluster Pipelines
### YAML Template Files
* `recreate-aks-template.yml`:  This is used by the various YAML pipelines and performs the exact same functionality for all
* 'recreate-aks-template-test.yml`: The same as `recreate-aks-template.yml`, but used by `recreate-aks-test.yml` for testing new functionality and changes.

### YAML Pipeline Files
The pipeline files are:
* `recreate-aks-test.yml`: recreates a test cluster in the Sandbox subscription.  Useful for testing changes to the main `recreate-aks-template.yml` template.
* `recreate-aks-sandbox.yml`: recreates the `cnp-aks-sandbox-cluster` in the Sandbox CI environment.
* `recreate-aks-nonprod.yml`: recreates the `cnp-aks-cluster` in the nonprod/prod CI environment.

### Pipelines
Each YAML pipeline file has a corresponding pipeline, which pretty much does what it says.  Each one has a collection of variables that are environment-specific.

### Triggers
The continous integration triggers on YAML push have been __disabled__. The pipelines are queued on demand.

## OSBA (Open Service Broker for Azure) Pipelines
The files in `osba` create shared resources via OSBA.
