locals { 
  # store the first (and only) compartment returned from the data source in the local variable 
  publicsubnet = data.oci_core_subnets.publicsubnets.subnets[0]
} 

resource "oci_functions_application" "cloudnative_2021_fn_app" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}App"
  subnet_ids     = [local.publicsubnet]
}


resource "null_resource" "Login2OCIR" {
  depends_on = [oci_functions_application.test_fn_app,
    oci_identity_policy.faas_read_repos_tenancy_policy,
    oci_identity_policy.admin_manage_function_family_policy,
    oci_identity_dynamic_group.faas_dg,
  oci_identity_policy.faas_dg_policy]

  provisioner "local-exec" {
    command = "echo '${var.ocir_user_password}' |  docker login ${local.ocir_docker_repository} --username ${local.ocir_namespace}/${var.ocir_user_name} --password-stdin"
  }
}

resource "null_resource" "FnPush2OCIR" {
  depends_on = [null_resource.Login2OCIR, oci_functions_application.cloudnative_2021_fn_app]

  provisioner "local-exec" {
    command     = "image=$(docker images | grep ${local.app_name_lower} | awk -F ' ' '{print $3}') ; docker rmi -f $image &> /dev/null ; echo $image"
    working_dir = "functions/${local.app_name_lower}"
  }

  provisioner "local-exec" {
    command     = "fn build --verbose"
    working_dir = "functions/${local.app_name_lower}"
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep ${local.app_name_lower} | awk -F ' ' '{print $3}') ; docker tag $image ${local.ocir_docker_repository}/${local.ocir_namespace}/${var.ocir_repo_name}/${local.app_name_lower}:${var.app_version}"
    working_dir = "functions/${local.app_name_lower}"
  }

  provisioner "local-exec" {
    command     = "docker push ${local.ocir_docker_repository}/${local.ocir_namespace}/${var.ocir_repo_name}/${local.app_name_lower}:${var.app_version}"
    working_dir = "functions/${local.app_name_lower}"
  }

}

resource "oci_functions_function" "test_fn" {
  depends_on     = [null_resource.FnPush2OCIR]
  application_id = oci_functions_application.cloudnative_2021_fn_app.id
  display_name   = var.app_name
  image          = "${local.ocir_docker_repository}/${local.ocir_namespace}/${var.ocir_repo_name}/${local.app_name_lower}:${var.app_version}"
  memory_in_mbs  = "256"
}
