resource "oci_identity_dynamic_group" "faas_dg" {
  provider       = var.region
  name           = "${var.app_name}-faas-dg-${random_id.tag.hex}"
  description    = "${var.app_name}-faas-dg-${random_id.tag.hex}"
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${var.compartment_ocid}'}"

  provisioner "local-exec" {
    command = "sleep 5"
  }
}