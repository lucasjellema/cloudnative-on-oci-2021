## Deployment Pipeline
## inspired by https://github.com/oracle-quickstart/oci-arch-devops/tree/master/devops_function

resource "oci_logging_log_group" "cloudnative2021_log_group" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}_log_group"
}

resource "oci_logging_log" "cloudnative2021_log" {
  display_name = "${var.app_name}_log"
  log_group_id = oci_logging_log_group.cloudnative2021_log_group.id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "all"
      resource    = oci_devops_project.cloudnative2021_project.id
      service     = "devops"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }

  is_enabled         = true
  retention_duration = var.project_logging_config_retention_period_in_days
}

resource "oci_ons_notification_topic" "cloudnative2021_notification_topic" {
  compartment_id = var.compartment_ocid
  name           = "${var.app_name}_topic"
}

resource "oci_devops_project" "cloudnative2021_project" {
  compartment_id = var.compartment_ocid
  name           = "${var.app_name}_devops_project"
  notification_config {
    topic_id = oci_ons_notification_topic.cloudnative2021_notification_topic.id
  }
  description  = "${var.app_name}_devops_project"
}

resource "oci_devops_deploy_environment" "cloudnative2021_tweetretriever_environment" {
  display_name            = "${var.app_name}_devops_environment"
  description             = "${var.app_name}_devops_environment"
  deploy_environment_type = "FUNCTION"
  project_id              = oci_devops_project.cloudnative2021_project.id
  function_id             = oci_functions_function.tweet_retriever_fn.id
}

resource "oci_devops_deploy_environment" "cloudnative2021_tweetreportdigester_environment" {
  display_name            = "${var.app_name}_tweetreportdigester_environment"
  description             = "${var.app_name}_tweetreportdigester_environment"
  deploy_environment_type = "FUNCTION"
  project_id              = oci_devops_project.cloudnative2021_project.id
  function_id             = oci_functions_function.tweet_report_digester_fn.id
}

resource "oci_devops_deploy_artifact" "cloudnative2021_tweetretriever_deploy_ocir_artifact" {
  depends_on                 = [null_resource.FnTweetRetrieverPush2OCIR]
  project_id                 = oci_devops_project.cloudnative2021_project.id
  deploy_artifact_type       = "DOCKER_IMAGE"
  argument_substitution_mode = "NONE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri                   = "${local.ocir_docker_repository}/${local.ocir_namespace}/${var.ocir_repo_name}/tweet_retriever:${var.app_version}"
  }
}

resource "oci_devops_deploy_artifact" "cloudnative2021_tweetreportdigester_deploy_ocir_artifact" {
  depends_on                 = [null_resource.FnPush2OCIR]
  project_id                 = oci_devops_project.cloudnative2021_project.id
  deploy_artifact_type       = "DOCKER_IMAGE"
  argument_substitution_mode = "NONE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri                   = "${local.ocir_docker_repository}/${local.ocir_namespace}/${var.ocir_repo_name}/fake-fun:0.0.1"
  }
}

resource "oci_devops_deploy_pipeline" "cloudnative2021_tweetretriever_deploy_pipeline" {
  project_id   = oci_devops_project.cloudnative2021_project.id
  description  = "${var.app_name}_tweetretriever_devops_pipeline"
  display_name = "${var.app_name}_tweetretriever_devops_pipeline"

  deploy_pipeline_parameters {
    items {
      name          = "name"
      default_value = "defaultValue"
      description   = "description"
    }
  }
}

resource "oci_devops_deploy_pipeline" "cloudnative2021_tweetreportdigester_deploy_pipeline" {
  project_id   = oci_devops_project.cloudnative2021_project.id
  description  = "${var.app_name}_tweetreportdigester_devops_pipeline"
  display_name = "${var.app_name}_tweetreportdigester_devops_pipeline"

  deploy_pipeline_parameters {
    items {
      name          = "name"
      default_value = "defaultValue"
      description   = "description"
    }
  }
}

resource "oci_devops_deploy_stage" "cloudnative2021_tweetretriever_deploy_stage" {
  deploy_pipeline_id = oci_devops_deploy_pipeline.cloudnative2021_tweetretriever_deploy_pipeline.id
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.cloudnative2021_tweetretriever_deploy_pipeline.id
    }
  }
  deploy_stage_type = "DEPLOY_FUNCTION"


  description  = "${var.app_name}_tweetretriever_devops_deploy_stage"
  display_name = "${var.app_name}_tweetretriever_devops_deploy_stage"

  namespace                       = "default"
  function_deploy_environment_id  = oci_devops_deploy_environment.cloudnative2021_tweetretriever_environment.id
  docker_image_deploy_artifact_id = oci_devops_deploy_artifact.cloudnative2021_tweetretriever_deploy_ocir_artifact.id
}


resource "oci_devops_deploy_stage" "cloudnative2021_tweetreportdigester_deploy_stage" {
  deploy_pipeline_id = oci_devops_deploy_pipeline.cloudnative2021_tweetreportdigester_deploy_pipeline.id
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.cloudnative2021_tweetreportdigester_deploy_pipeline.id
    }
  }
  deploy_stage_type = "DEPLOY_FUNCTION"


  description  = "${var.app_name}_tweetreportdigester_devops_deploy_stage"
  display_name = "${var.app_name}_tweetreportdigester_devops_deploy_stage"

  namespace                       = "default"
  function_deploy_environment_id  = oci_devops_deploy_environment.cloudnative2021_tweetreportdigester_environment.id
  docker_image_deploy_artifact_id = oci_devops_deploy_artifact.cloudnative2021_tweetreportdigester_deploy_ocir_artifact.id
}

resource "oci_devops_deployment" "test_deployment_run" {
  depends_on         = [null_resource.FnTweetRetrieverPush2OCIR, oci_devops_deploy_stage.cloudnative2021_tweetretriever_deploy_stage]
  deploy_pipeline_id = oci_devops_deploy_pipeline.cloudnative2021_tweetretriever_deploy_pipeline.id
  deployment_type    = "PIPELINE_DEPLOYMENT"
  display_name       = "${var.app_name}_tweetretriever_${random_string.deploy_id.result}_devops_deployment"
}