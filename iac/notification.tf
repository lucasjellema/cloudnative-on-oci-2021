resource "oci_ons_notification_topic" "cloudnative2021_twitter_report_alerts_topic" {
  compartment_id = var.compartment_ocid
  name           = "TWITTER_REPORT_ALERT"
}