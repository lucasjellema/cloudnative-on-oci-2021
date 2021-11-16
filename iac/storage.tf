resource "oci_objectstorage_bucket" "twitter_reports_bucket" {
    #Required
    compartment_id = var.compartment_ocid
    name = var.bucket_name
    namespace = local.bucket_namespace
    object_events_enabled = true # we want an event to published when a new twitter report is created
}