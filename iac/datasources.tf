data "oci_core_subnets" "publicsubnets" { 
  compartment_id = var.compartment_ocid 
  # only retain the subnets that allow public traffic 
  filter { 
     name = "prohibit_public_ip_on_vnic" 
     values = [ "false"] 
  }
}

data "oci_core_vcns" "cloudnative_2021_vcns" {
    #fetch all VCNS in compartment (there will be only one)
    compartment_id = var.compartment_ocid
}

# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

# Gets home and current regions
data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid

  provider = oci.current_region
}

data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenant_details.home_region_key]
  }

  provider = oci.region
}


data "oci_identity_tenancy" "oci_tenancy" {
  tenancy_id = var.tenancy_ocid
}

# OCI Services
## Available Services
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_identity_regions" "oci_regions" {

  filter {
    name   = "name"
    values = [var.region]
  }

}

data "oci_objectstorage_namespace" "os_namespace" {
  compartment_id = var.tenancy_ocid
}


# Randoms
resource "random_string" "deploy_id" {
  length  = 4
  special = false
}