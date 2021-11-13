# cloudnative-on-oci-2021
Resources for the Cloud Native on OCI demonstrations (end of 2021)


## Installation of Infra and Application on OCI

Steps:
* specify the target compartment's OCID to have resources created in proper compartment
* run Infrastructure as Code Terraform scripts to create OCI resources
* define dynamic groups & dynamic group policies (to provide permissions to functions)
* define Function Application configuration (to provide settings to functions)
* define Vault Secrets (to provide sensitive settings to functions, such as Twitter credentials)
* build functions (to container images) and deploy functions (from container images) (ideally using OCI DevOps Build Pipeline and Deployment Pipeline) 