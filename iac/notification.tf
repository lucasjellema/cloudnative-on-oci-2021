resource "oci_ons_notification_topic" "cloudnative2021_twitter_report_alerts_topic" {
  compartment_id = var.compartment_ocid
  name           = "TWITTER_REPORT_ALERT"
}

resource oci_events_rule export_TWITTER_REPORT_EVENTS {
depends_on     = [oci_ons_notification_topic.cloudnative2021_twitter_report_alerts_topic, oci_objectstorage_bucket.twitter_reports_bucket]
  actions {
    actions {
      action_type = "ONS"
      is_enabled = "true"
      topic_id = oci_ons_notification_topic.cloudnative2021_twitter_report_alerts_topic.id
    }
  }
  compartment_id = var.compartment_ocid
  condition      = "{\"eventType\":[\"com.oraclecloud.objectstorage.createobject\"],\"data\":{\"additionalDetails\":{\"bucketName\":[\"${oci_objectstorage_bucket.twitter_reports_bucket.name\"]}}}"
  description  = "When a Twitter Report becomes available (document added to bucket) a Notification is to be published for the benefit of consumers to act upon"
  display_name = "TWITTER_REPORT_EVENTS"
  is_enabled = "true"
}
