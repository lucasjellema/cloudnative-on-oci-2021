# cloudnative-on-oci-2021
Resources for the Cloud Native on OCI demonstrations (end of 2021)


## Installation of Infra and Application on OCI

Prepare:
* create compartment in OCI (or empty existing compartment for reuse)
* run VCN networking wizard to create a VCN with Internet Connectivity (https://console.us-ashburn-1.oraclecloud.com/networking/solutions/vcn)

* either use OCI CloudShell 
* or start an environment and make sure Terraform can be used in it (see below for setting up Terraform) and that the Fn client is available (see below)
* git clone this repository: git clone https://github.com/lucasjellema/cloudnative-on-oci-2021
* when not in CloudShell: 
  * edit files .oci/config and .oci/oci_api_key.pem to contain proper values
  * copy directory .oci to ~/.oci  (cp -r .oci ~)

* edit file variables.tf in directory /iac (for example to * specify the target compartment's OCID to have resources created in proper compartment)

* initialize terraform: execute `terraform init` in the /iac subdirectory in the cloned repository

Steps:
* run Infrastructure as Code Terraform scripts to create OCI resources: (in /iac) terraform apply
* try (from Postman) the ping API on the API Gateway: https://152.70.199.164/cn2021/ping  (replace with the public ip address assigned to the Internet Gateway)

* define Function Application configuration (to provide settings to functions)
* define Vault Secrets (to provide sensitive settings to functions, such as Twitter credentials)
* build functions (to container images) and deploy functions (from container images) (ideally using OCI DevOps Build Pipeline and Deployment Pipeline) 


### Set up Terraform:

git clone https://github.com/robertpeteuil/terraform-installer
./terraform-installer/terraform-install.sh
terraform version

the last step shows the version and the system (such as Linux AMD64)


Note: As an aside, to support discovery (of existing OCI resources with Terraform OCI Provider, go through these steps):
cd ./terraform-installer
REM determine the latest/current terraform-provider-oci for the platform from https://releases.hashicorp.com/terraform-provider-oci/ 
wget https://releases.hashicorp.com/terraform-provider-oci/4.52.0/terraform-provider-oci_4.52.0_linux_amd64.zip
unzip terraform-provider-oci_4.52.0_linux_amd64.zip

to do discovery:
./terraform-provider-oci_v4.52.0_x4 -command=export -compartment_name="gb-tour-2020-latam" -services=availability_domain,apigateway -output_path=/root/iac


### Set up Fn Client 

Check on [Fn Project](https://fnproject.io/tutorials/install/)
```
curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh
```