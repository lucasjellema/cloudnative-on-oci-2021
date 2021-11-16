resource oci_kms_vault cloudnative-2021-vault {
  compartment_id = var.compartment_ocid
  display_name = "cloudnative-2021-vault"
  vault_type = "DEFAULT"
}