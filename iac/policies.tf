## DEVOPS
resource "oci_identity_dynamic_group" "devops_pipln_dg" {
  compartment_id = var.tenancy_ocid
  name           = "${var.app_name}-devops-pipln-dg"
  description    = "${var.app_name} DevOps Pipeline Dynamic Group"
  matching_rule  = "All {resource.type = 'devopsdeploypipeline', resource.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_policy" "devops_compartment_policies" {
  depends_on  = [oci_identity_dynamic_group.devops_pipln_dg]
  name        = "${var.app_name}-devops-compartment-policies"
  description = "${var.app_name} DevOps Compartment Policies"
  compartment_id = var.tenancy_ocid
  statements     = local.allow_devops_manage_compartment_statements
}

locals {
  devops_pipln_dg = oci_identity_dynamic_group.devops_pipln_dg.name
  allow_devops_manage_compartment_statements = [
    "Allow dynamic-group ${local.devops_pipln_dg} to manage all-resources in compartment id ${var.compartment_ocid}"
  ]
}


## FUNCTIONS

resource "oci_identity_dynamic_group" "faas_dg" {
  name           = "${var.app_name}-faas-dg"
  description    = "${var.app_name}-faas-dg"
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${var.compartment_ocid}'}"

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_identity_policy" "faas_read_repos_tenancy_policy" {
  name           = "${var.app_name}-faas-read-repos-tenancy-policy"
  description    = "${var.app_name}-faas-read-repos-tenancy-policy"
  compartment_id = var.tenancy_ocid
  statements     = ["Allow service FaaS to read repos in tenancy"]
  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_identity_policy" "admin_manage_function_family_policy" {
  
  depends_on     = [oci_identity_policy.faas_read_repos_tenancy_policy]
  name           = "${var.app_name}-admin-manage-function-family-policy"
  description    = "${var.app_name}-admin-manage-function-family-policy"
  compartment_id = var.compartment_ocid
  statements = ["Allow group Administrators to manage functions-family in compartment id ${var.compartment_ocid}",
  "Allow group Administrators to read metrics in compartment id ${var.compartment_ocid}"]
  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_identity_policy" "admin_use_vcn_family_policy" {
   
  depends_on     = [oci_identity_policy.admin_manage_function_family_policy]
  name           = "${var.app_name}-admin-use-vcn-family-policy"
  description    = "${var.app_name}-admin-use-vcn-family-policy"
  compartment_id = var.compartment_ocid
  statements     = ["Allow group Administrators to use virtual-network-family in compartment id ${var.compartment_ocid}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_identity_policy" "faas_use_vcn_family_policy" {
   
  depends_on     = [oci_identity_policy.admin_use_vcn_family_policy]
  name           = "${var.app_name}-faas-use-vcn-family-policy"
  description    = "${var.app_name}-faas-use-vcn-family-policy"
  compartment_id = var.tenancy_ocid
  statements     = ["Allow service FaaS to use virtual-network-family in compartment id ${var.compartment_ocid}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_identity_policy" "faas_dg_policy" {
   
  depends_on     = [oci_identity_dynamic_group.faas_dg]
  name           = "${var.app_name}-faas-dg-policy"
  description    = "${var.app_name}-faas-dg-policy"
  compartment_id = var.compartment_ocid
  statements     = ["allow dynamic-group ${oci_identity_dynamic_group.faas_dg.name} to manage all-resources in compartment id ${var.compartment_ocid}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

### Vault interactions

resource "oci_identity_policy" "vault_functions_read_secrets_dg_policy" {   
  depends_on     = [oci_identity_dynamic_group.faas_dg]
  name           = "${var.app_name}-vault_functions_read_secrets_dg_policy"
  description    = "${var.app_name}-vault_functions_read_secrets_dg_policy"
  compartment_id = var.compartment_ocid
  statements     = ["allow dynamic-group ${oci_identity_dynamic_group.faas_dg.name} to read secret-family in compartment id ${var.compartment_ocid}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

# Create a policy that grants write access on objects in Object Storage in the compartment to all functions in that compartment :

resource "oci_identity_policy" "objectstorage_functions_writeobjects_dg_policy" {   
  depends_on     = [oci_identity_dynamic_group.faas_dg]
  name           = "${var.app_name}-objectstorage_functions_writeobjects_dg_policy"
  description    = "${var.app_name}-objectstorage_functions_writeobjects_dg_policy"
  compartment_id = var.compartment_ocid
  statements     = ["allow dynamic-group ${oci_identity_dynamic_group.faas_dg.name} to manage objects in compartment id ${var.compartment_ocid}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}