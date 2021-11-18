resource oci_nosql_table nosql_TWEETS_TABLE {
  compartment_id = var.compartment_ocid
  ddl_statement  = "CREATE TABLE TWEETS_TABLE ( id long, text string, author string, tweet_timestamp timestamp(0), language string, hashtags string, PRIMARY KEY ( SHARD ( id ) ) )"
  is_auto_reclaimable = "false"
  name                = "TWEETS_TABLE"
  table_limits {
    max_read_units     = "1"
    max_storage_in_gbs = "1"
    max_write_units    = "1"
  }
}

