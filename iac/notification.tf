resource "oci_ons_notification_topic" "cloudnative2021_twitter_report_alerts_topic" {
  compartment_id = var.compartment_ocid
  name           = "TWITTER_REPORT_ALERT"
}

resource oci_events_rule bucket_object_to_topic_notification_TWITTER_REPORT_EVENTS {
depends_on     = [oci_ons_notification_topic.cloudnative2021_twitter_report_alerts_topic, oci_objectstorage_bucket.twitter_reports_bucket]
  actions {
    actions {
      action_type = "ONS"
      is_enabled = "true"
      topic_id = oci_ons_notification_topic.cloudnative2021_twitter_report_alerts_topic.id
    }
  }
  compartment_id = var.compartment_ocid
  condition      = "{\"eventType\":[\"com.oraclecloud.objectstorage.createobject\"],\"data\":{\"additionalDetails\":{\"bucketName\":[\"${oci_objectstorage_bucket.twitter_reports_bucket.name}\"]}}}"
  description  = "When a Twitter Report becomes available (document added to bucket) a Notification is to be published for the benefit of consumers to act upon"
  display_name = "TWITTER_REPORT_EVENTS"
  is_enabled = "true"
}


resource oci_ons_subscription tweet_report_digester_subscription_on_topic {
  depends_on     = [ oci_ons_notification_topic.cloudnative2021_twitter_report_alerts_topic, oci_functions_function.tweet_report_digester_fn]
  compartment_id = var.compartment_ocid
  delivery_policy = "{\"backoffRetryPolicy\":{\"maxRetryDuration\":7200000,\"policyType\":\"EXPONENTIAL\"}}"
  endpoint        = "${oci_functions_function.tweet_report_digester_fn.id}"
  freeform_tags = {
  }
  protocol = "ORACLE_FUNCTIONS"
  topic_id = oci_ons_notification_topic.cloudnative2021_twitter_report_alerts_topic.id
}

resource oci_ons_subscription emailsubscription_subscription_on_topic {
  compartment_id = var.compartment_ocid
  delivery_policy = "{\"backoffRetryPolicy\":{\"maxRetryDuration\":7200000,\"policyType\":\"EXPONENTIAL\"}}"
  endpoint        = var.email_address_to_end_notification_of_tweetreport_to
  protocol = "EMAIL"
  topic_id = oci_ons_notification_topic.export_TWITTER_REPORT_ALERT.id
}