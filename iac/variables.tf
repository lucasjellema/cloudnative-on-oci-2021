variable compartment_ocid { default = "define your target compartment id" }
variable region { default = "define your target region, for example us-ashburn-1" }
variable app_name {default = "cloudnative-2021"}
variable app_version {default = "0.0.1"}
variable tenancy_ocid {default = "define the ocid of the tenancy"}
variable ocir_user_name { default = "define the username for the OCIR repos"}
variable ocir_user_password {
    default = "password for OCIR repos"
    sensitive = true
    }

variable "ocir_repo_name" {
  default = "cloudnative-2021/functions"
}


locals {
  app_name_lower = lower(var.app_name)
}

# OCIR repo name & namespace

locals {
  ocir_docker_repository = join("", [lower(lookup(data.oci_identity_regions.oci_regions.regions[0], "key")), ".ocir.io"])
  ocir_namespace         = lookup(data.oci_objectstorage_namespace.os_namespace, "namespace")
}

# DEVOPS

variable project_logging_config_retention_period_in_days { default = 30}

# Storage
variable "bucket_name" {
  # this value is used to create the bucket from and should be passed as parameter to the tweet_retriever function
  default = "twitter_reports"
}

locals { 
  bucket_namespace = lookup(data.oci_objectstorage_namespace.os_namespace, "namespace")
}
