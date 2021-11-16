


locals { 
  # store the first (and only) compartment returned from the data source in the local variable 
  publicsubnet = data.oci_core_subnets.publicsubnets.subnets[0]
  vcn_id = data.oci_core_vcns.cloudnative_2021_vcns.virtual_networks[0].id
} 

 
output "publicsubnet" { 
  value = local.publicsubnet
}
output "vcn_id" { 
  value = local.vcn_id
}
    



resource oci_apigateway_gateway cloudnative-2021-apigateway {
  compartment_id = var.compartment_ocid
  display_name  = "cloudnative-2021-gateway"
  endpoint_type = "PUBLIC"
  freeform_tags = {
  }
  network_security_group_ids = [
  ]
  response_cache_details {
    #authentication_secret_id = <<Optional value not found in discovery>>
    #authentication_secret_version_number = <<Optional value not found in discovery>>
    #connect_timeout_in_ms = <<Optional value not found in discovery>>
    #is_ssl_enabled = <<Optional value not found in discovery>>
    #is_ssl_verify_disabled = <<Optional value not found in discovery>>
    #read_timeout_in_ms = <<Optional value not found in discovery>>
    #send_timeout_in_ms = <<Optional value not found in discovery>>
    #servers = <<Optional value not found in discovery>>
    type = "NONE"
  }
  subnet_id = local.publicsubnet.id
}


resource oci_apigateway_deployment apigw-deployment_cloudnative-2021 {
 depends_on = [oci_apigateway_gateway.cloudnative-2021-apigateway , oci_functions_function.tweet_retriever_fn  ]
  compartment_id = var.compartment_ocid
  display_name = "cloudnative-2021"
  freeform_tags = {
  }
  gateway_id  = oci_apigateway_gateway.cloudnative-2021-apigateway.id
  path_prefix = "/cn2021"
  specification {
    logging_policies {
      execution_log {
        is_enabled = "true"
        log_level  = "INFO"
      }
    }
    request_policies {
    }
    routes {
      backend {
        body = "Ping successful"
        headers {
          name  = "Content-Type"
          value = "text/plain"
        }
        status = "200"
        type   = "STOCK_RESPONSE_BACKEND"
      }
      logging_policies {
        #access_log = <<Optional value not found in discovery>>
        execution_log {
          #is_enabled = <<Optional value not found in discovery>>
          log_level = ""
        }
      }
      methods = [
        "GET",
      ]
      path = "/ping"
      request_policies {
      }
      response_policies {
      }
    }
    routes {
      backend {
        function_id = oci_functions_function.tweet_retriever_fn.id
        type = "ORACLE_FUNCTIONS_BACKEND"
      }
      logging_policies {
        execution_log {
          log_level = ""
        }
      }
      methods = [
        "GET",
      ]
      path = "/retrieve-tweets"
      request_policies {
      }
      response_policies {
      }
    }

  }
}

# add an additional security list with a single ingress rule to allow inbound https traffic
resource oci_core_security_list inbound-https-for-vcn-cloudnative-2021-security-list {
  compartment_id = var.compartment_ocid
  display_name = "Additional Security List for vcn-cloudnative-2021 allowing inbound https traffic"
  ingress_security_rules {
    description = "Allow HTTPS network traffic from any origin to Port 443"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  vcn_id = local.vcn_id
}

data "oci_core_public_ips" "public_ips" {
  depends_on     = [oci_core_security_list.inbound-https-for-vcn-cloudnative-2021-security-list]
    #Required
    compartment_id = var.compartment_ocid
    scope = "REGION"
    # lifetime = "RESERVED"

    
}

output "publicipaddress" { 
  value = local.public_ip[0].ip_address
}
output "publicipaddresses" { 
  value = local.public_ip
}

locals {
  public_ip =  data.oci_core_public_ips.public_ips.public_ips
}
