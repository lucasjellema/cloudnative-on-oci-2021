## DEVOPS
resource "oci_identity_dynamic_group" "devops_pipln_dg" {
  compartment_id = var.tenancy_ocid
  name           = "${var.app_name}-devops-pipln-dg"
  description    = "${var.app_name} DevOps Pipeline Dynamic Group"
  matching_rule  = "All {resource.type = 'devopsdeploypipeline', resource.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_dynamic_group" "devops_buildpipeline_dg" {
  compartment_id = var.tenancy_ocid
  name           = "${var.app_name}-devops_buildpipeline_dg"
  description    = "${var.app_name} DevOps Build Pipeline Dynamic Group"
  matching_rule  = "All {resource.type = 'devopsbuildpipeline', resource.compartment.id = '${var.compartment_ocid}'}"
}
resource "oci_identity_dynamic_group" "cloudnative2021-devops_coderepositories" {
  compartment_id = var.tenancy_ocid
  name           = "cloudnative2021-devops_coderepositories-dg"
  description    = "cloudnative2021-devops_coderepositories-dg DevOps Code Repositories Dynamic Group"
  matching_rule  = "All {resource.type = 'devopsrepository', resource.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_policy" "devops_compartment_policies" {
  depends_on  = [oci_identity_dynamic_group.devops_pipln_dg]
  name        = "${var.app_name}-devops-compartment-policies"
  description = "${var.app_name} DevOps Compartment Policies"
  compartment_id = var.tenancy_ocid
  statements     = local.allow_devops_manage_compartment_statements
}



resource "oci_identity_policy" "devops_buildpipeline-dg_policies" {
  depends_on  = [oci_identity_dynamic_group.devops_buildpipeline_dg]
  name        = "${var.app_name}-devops_buildpipeline-dg_policies"
  description = "${var.app_name} DevOps Build Pipeline Policies"
  compartment_id = var.tenancy_ocid
  ## Provide access to read deployment artifacts in the Deliver Artifacts stage, read DevOps code repository in the Build stage, and trigger deployment pipeline in the Trigger Deploy stage
  ## To deliver artifacts, provide access to the Artifact Registry
  ## To deliver artifacts, provide access to the Container Registry (OCIR):
  statements     = ["Allow dynamic-group ${oci_identity_dynamic_group.devops_buildpipeline_dg.name} to manage devops-family in compartment id ${var.compartment_ocid}"
  , "Allow dynamic-group ${oci_identity_dynamic_group.devops_buildpipeline_dg.name} to manage generic-artifacts in compartment id ${var.compartment_ocid}"
  , "Allow dynamic-group ${oci_identity_dynamic_group.devops_buildpipeline_dg.name} to manage repos in compartment id ${var.compartment_ocid}"
  ]
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


### API Gateway - permission to invoke functions

resource "oci_identity_policy" "apigateway-invoke-functions-policy" {
   
  depends_on     = [oci_identity_dynamic_group.faas_dg]
  name           = "apigateway-invoke-functions-policy"
  description    = "apigateway-invoke-functions-policy"
  compartment_id = var.compartment_ocid
  statements     = ["ALLOW any-user to use functions-family in compartment id ${var.compartment_ocid} where ALL {request.principal.type= 'ApiGateway', request.resource.compartment.id = '${var.compartment_ocid}'}"]
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

# according to docs, the read secrets should be granted to devopsconnection; however, that does not work : it works for coderepositories (https://docs.public.oneportal.content.oci.oraclecloud.com/en-us/iaas/Content/devops/using/devops_policy_examples.htm) 

resource "oci_identity_policy" "vault_devops_coderepos_read_secrets_policy" {     
  depends_on     = [oci_identity_dynamic_group.cloudnative2021-devops_coderepositories]
  name           = "vault_devops_read_secrets_policy"
  description    = "vault_devops_read_secrets_policy"
  compartment_id = var.compartment_ocid
  statements     = ["allow dynamic-group ${oci_identity_dynamic_group.cloudnative2021-devops_coderepositories.name} to read secret-family in compartment id ${var.compartment_ocid}"]
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


# Create a policy that grants create record in NoSQL Database in the compartment to all functions in that compartment :

resource "oci_identity_policy" "nosql_functions_create_records_dg_policy" {   
  depends_on     = [oci_identity_dynamic_group.faas_dg]
  name           = "${var.app_name}-nosql_functions_createrecords_dg_policy"
  description    = "${var.app_name}-nosql_functions_createrecords_dg_policy"
  compartment_id = var.compartment_ocid
  statements     = ["allow dynamic-group ${oci_identity_dynamic_group.faas_dg.name} to use nosql-rows in compartment id ${var.compartment_ocid}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

# Create a policy that grants publish to Stream  to all functions in that compartment :
oci iam policy create  --name "publish-stream-permissions-for-resource-principal-enabled-functions-in-lab-compartment" --compartment-id $compartmentId  --statements "[ \"allow dynamic-group functions-in-lab-compartment
 to use stream-push  in compartment lab-compartment\" ]" --description "to allow functions in lab-compartment to push messages to streams"


resource "oci_identity_policy" "streaming_functions_publish_dg_policy" {   
  depends_on     = [oci_identity_dynamic_group.faas_dg]
  name           = "${var.app_name}-streaming_functions_push_dg_policy"
  description    = "${var.app_name}-streaming_functions_push_dg_policy"
  compartment_id = var.compartment_ocid
  statements     = ["allow dynamic-group ${oci_identity_dynamic_group.faas_dg.name} to use stream-push in compartment id ${var.compartment_ocid}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}