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
* define Vault Secret (to provide sensitive settings to functions, for now only Twitter credentials)
* define Function Application configuration (to provide settings to functions; for now only the ocid of the vault secret for Twitter credentials)
* make call to tweet-retriever function - something like: https://150.230.164.102/cn2021/retrieve-tweets?hashtag=brexit&minutes=10  - replace the IP address with the address assigned to the VCN
* (iteratively) build functions (to container images) and deploy functions (from container images) (ideally using OCI DevOps Build Pipeline and Deployment Pipeline) 


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



## Query Resources in Cloud CloudShell

In OCI CloudShell, we have both the OCI CLI and Terraform at our disposal, both come preconfigured. Here

To query details for an OCI Cloud Resource - say a code repository - we can use both the CLI and Terraform.

Using the CLI:
oci devops repository get --repository-id "ocid1.devopsrepository.oc1.iad.amaaaaaa6sde7caaqtruts6p3rb533dnevklmf6xqw7eknk3bqqrxdk2nmsa"

and using Terraform:
* create a file - for example called query.tf (touch query.tf)
* add this contents to the file (nano query.tf; paste in this text, change the region if you are in a different one):
data "oci_devops_repository" "result" {
    repository_id = "ocid1.devopsrepository.oc1.iad.amaaaaaa6sde7caaqtruts6p3rb533dnevklmf6xqw7eknk3bqqrxdk2nmsa"
}

output "result" {
  value = data.oci_devops_repository.result
}

provider oci {
   region = "us-ashburn-1"
}

* run terraform init
* run terraform apply


To extract the resource definition in the form of a Terraform plan:
* install the provider
cd somedirectory of your choosing
wget https://releases.hashicorp.com/terraform-provider-oci/4.52.0/terraform-provider-oci_4.52.0_linux_amd64.zip
unzip terraform-provider-oci_4.52.0_linux_amd64.zip
* run the discovery
to do discovery:
./terraform-provider-oci_v4.52.0_x4 -command=export -compartment_name="cloudnative-2021" -services=devops -output_path=. 




## NoSQL in Cloud Shell OCI CLI

oci nosql query execute  -c ocid1.compartment.oc1..aaaaaaaacsssekayq4d34nl5h3eqs5e6ak3j5s4jhlws6oxf7rr5pxmt3zrq --statement "SELECT * FROM TWEETS_TABLE"  --limit 20

oci nosql query execute  -c ocid1.compartment.oc1..aaaaaaaacsssekayq4d34nl5h3eqs5e6ak3j5s4jhlws6oxf7rr5pxmt3zrq --statement "SELECT *  FROM TWEETS_TABLE WHERE tweet_timestamp > CAST(\"2021-11-25T14:18:05\" AS TIMESTAMP)"  --limit 20



SELECT *  FROM TWEETS_TABLE WHERE tweet_timestamp > CAST("2021-11-26T14:18:05" AS TIMESTAMP)

WHERE contains(text,"search string")
WHERE language = 'nl'

SELECT * FROM TWEETS_TABLE WHERE contains(upper(text),upper("virus")) and contains(upper(hashtags),upper("#omt"))


oci nosql query execute  -c ocid1.compartment.oc1..aaaaaaaacsssekayq4d34nl5h3eqs5e6ak3j5s4jhlws6oxf7rr5pxmt3zrq --statement "SELECT *  FROM TWEETS_TABLE WHERE WHERE contains(text,\"virus\")"  --limit 20

oci nosql index create --index-name tweet_time_idx1 --table-name-or-id TWEETS_TABLE --compartment-id ocid1.compartment.oc1..aaaaaaaacsssekayq4d34nl5h3eqs5e6ak3j5s4jhlws6oxf7rr5pxmt3zrq --keys   "[  {  \"columnName\": \"tweet_timestamp\"}]"



