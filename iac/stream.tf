resource oci_streaming_stream_pool streampool_DefaultPool {
  compartment_id = var.compartment_ocid
  kafka_settings {
    auto_create_topics_enable = "false"
    log_retention_hours       = "24"
    num_partitions            = "1"
  }
  name = "DefaultPool"

  # Required attributes that were not found in discovery have been added to lifecycle ignore_changes
  # This is done to avoid terraform plan failure for the existing infrastructure
  lifecycle {
    ignore_changes = [custom_encryption_key[0].kms_key_id]
  }
}

resource oci_streaming_stream cloudnative-2021-tweet-stream {
  compartment_id = var.compartment_ocid

  name               = "cloudnative-2021-tweet-stream"
  partitions         = "1"
  retention_in_hours = "24"
}

