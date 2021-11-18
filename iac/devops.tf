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
  display_name            = "${var.app_name}_tweetretriever_devops_environment"
  description             = "${var.app_name}_tweetretriever_devops_environment"
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

resource "oci_devops_deploy_artifact" "cloudnative2021_fakefun_deploy_ocir_artifact" {
  depends_on                 = [null_resource.FnPush2OCIR]
  project_id                 = oci_devops_project.cloudnative2021_project.id
  deploy_artifact_type       = "DOCKER_IMAGE"
  argument_substitution_mode = "NONE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri                   = "${local.ocir_docker_repository}/${local.ocir_namespace}/${var.ocir_repo_name}/fake-fun:0.0.1"
  }
}

resource "oci_devops_deploy_artifact" "cloudnative2021_tweetreportdigester_deploy_ocir_artifact" {
  depends_on                 = [null_resource.FnPush2OCIR]
  project_id                 = oci_devops_project.cloudnative2021_project.id
  deploy_artifact_type       = "DOCKER_IMAGE"
  argument_substitution_mode = "NONE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri                   = "${local.ocir_docker_repository}/${local.ocir_namespace}/${var.ocir_repo_name}/tweet_report_digester:0.0.1"
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

### this resource represents a trial run of deployment pipeline 
resource "oci_devops_deployment" "test_deployment_run_tweetretriever" {
  depends_on         = [null_resource.FnTweetRetrieverPush2OCIR, oci_devops_deploy_stage.cloudnative2021_tweetretriever_deploy_stage]
  deploy_pipeline_id = oci_devops_deploy_pipeline.cloudnative2021_tweetretriever_deploy_pipeline.id
  deployment_type    = "PIPELINE_DEPLOYMENT"
  display_name       = "${var.app_name}_tweetretriever_${random_string.deploy_id.result}_devops_deployment"
}


# Code Repository
# note: oci devops needs to be able to access Vault

resource "oci_devops_repository" "cloudnative-2021-on-oci-repo" {
    #Required
    name = "cloudnative-2021-on-oci-repo"
    project_id = oci_devops_project.cloudnative2021_project.id

    #Optional
    description = "Code Repository mirrored from GitHub https://github.com/lucasjellema/cloudnative-on-oci-2021"
    mirror_repository_config {

        #Optional
        connector_id = oci_devops_connection.devops_externalconnection_github-lucasjellema.id
        repository_url = "https://github.com/lucasjellema/cloudnative-on-oci-2021"
        trigger_schedule {
            #Required
            schedule_type = "DEFAULT"

        }
    }
    repository_type = "MIRRORED"
}

resource oci_devops_build_pipeline cloudnative2021_buildpipeline_tweet-retriever-function {

  description  = ""
  display_name = "build_tweet-retriever-function"
  freeform_tags = {
  }
  project_id = oci_devops_project.cloudnative2021_project.id
}


resource oci_devops_connection devops_externalconnection_github-lucasjellema {
  ## GitHub Personal Access Token is stored in Vault Secret with this OCID
  access_token    = "ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caax4fycl23zwgww24twfzq7cmo4ahb6yghiqhr5ergxhpq"
  connection_type = "GITHUB_ACCESS_TOKEN"
  description  = "Connection to GitHub Repositories in lucasjellema account"
  display_name = "github-lucasjellema"
  project_id = oci_devops_project.cloudnative2021_project.id
}

resource oci_devops_build_pipeline_stage build-stage_trigger-tweet-retriever-deployment-pipeline {
  build_pipeline_id = oci_devops_build_pipeline.cloudnative2021_buildpipeline_tweet-retriever-function.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build-stage-push-function-container-image-to-registry.id
    }
  }
  build_pipeline_stage_type = "TRIGGER_DEPLOYMENT_PIPELINE"
  deploy_pipeline_id = oci_devops_deploy_pipeline.cloudnative2021_tweetretriever_deploy_pipeline.id
  description        = "Trigger Deployment Pipeline for Function Tweet Retriever"
  display_name       = "trigger-tweet-retriever-deployment-pipeline"
  is_pass_all_parameters_enabled = "true"
}

resource oci_devops_build_pipeline_stage build-stage-push-function-container-image-to-registry {
  build_pipeline_id = oci_devops_build_pipeline.cloudnative2021_buildpipeline_tweet-retriever-function.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build-stage-tweet-retriever-function-container-image.id
    }
  }
  build_pipeline_stage_type = "DELIVER_ARTIFACT"

  deliver_artifact_collection {
    items {
      artifact_id   = oci_devops_deploy_artifact.cloudnative2021_tweetretriever_deploy_ocir_artifact.id
      artifact_name = "output01"
    }
  }
  #deploy_pipeline_id = <<Optional value not found in discovery>>
  description  = "Push the resulting container image for function tweet_retriever to Container Registry"
  display_name = "push-function-container-image-to-registry"
}

resource oci_devops_build_pipeline_stage build-stage-tweet-retriever-function-container-image {
  build_pipeline_id = oci_devops_build_pipeline.cloudnative2021_buildpipeline_tweet-retriever-function.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.cloudnative2021_buildpipeline_tweet-retriever-function.id
    }
  }
  build_pipeline_stage_type = "BUILD"
  build_source_collection {
    items {
      branch = "main"
      connection_type = "DEVOPS_CODE_REPOSITORY"
      name            = "tweet_retriever_source"
      repository_id   = oci_devops_repository.cloudnative-2021-on-oci-repo.id
      repository_url  = oci_devops_repository.cloudnative-2021-on-oci-repo.http_url  
      ## or use ssh_url ??
      ## "https://devops.scmservice.us-ashburn-1.oci.oraclecloud.com/namespaces/idtwlqf2hanz/projects/cloudnative-2021_devops_project/repositories/cloudnative-2021-on-oci-repo"
    }
  }
  build_spec_file = "/functions/tweet-summarizer/build_spec.yaml"
  description  = ""
  display_name = "build-function-container-image"
  image = "OL7_X86_64_STANDARD_10"
  primary_build_source               = "tweet_retriever_source"
  stage_execution_timeout_in_seconds = "36000"
}

### Build Pipeline tweet_report_digester_fn

resource oci_devops_build_pipeline cloudnative2021_buildpipeline_tweet-report-digester-function {

  description  = ""
  display_name = "build_tweet-report-digester-function"
  freeform_tags = {
  }
  project_id = oci_devops_project.cloudnative2021_project.id
}

resource oci_devops_build_pipeline_stage build-stage_trigger-tweet-report-digester-deployment-pipeline {
  build_pipeline_id = oci_devops_build_pipeline.cloudnative2021_buildpipeline_tweet-report-digester-function.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build-stage-push-tweet-report-digester-function-container-image-to-registry.id
    }
  }
  build_pipeline_stage_type = "TRIGGER_DEPLOYMENT_PIPELINE"
  deploy_pipeline_id = oci_devops_deploy_pipeline.cloudnative2021_tweetreportdigester_deploy_pipeline.id
  description        = "Trigger Deployment Pipeline for Function Tweet Report Digester"
  display_name       = "trigger-tweet-report-digester-deployment-pipeline"
  is_pass_all_parameters_enabled = "true"
}

resource oci_devops_build_pipeline_stage build-stage-push-tweet-report-digester-function-container-image-to-registry {
  build_pipeline_id = oci_devops_build_pipeline.cloudnative2021_buildpipeline_tweet-report-digester-function.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build-stage-tweet-report-digester-function-container-image.id
    }
  }
  build_pipeline_stage_type = "DELIVER_ARTIFACT"

  deliver_artifact_collection {
    items {
      artifact_id   = oci_devops_deploy_artifact.cloudnative2021_tweetreportdigester_deploy_ocir_artifact.id
      artifact_name = "output01"
    }
  }
  #deploy_pipeline_id = <<Optional value not found in discovery>>
  description  = "Push the resulting container image for function tweet_report_digester to Container Registry"
  display_name = "push-tweet-report-digester-function-container-image-to-registry"
}

resource oci_devops_build_pipeline_stage build-stage-tweet-report-digester-function-container-image {
  build_pipeline_id = oci_devops_build_pipeline.cloudnative2021_buildpipeline_tweet-report-digester-function.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.cloudnative2021_buildpipeline_tweet-report-digester-function.id
    }
  }
  build_pipeline_stage_type = "BUILD"
  build_source_collection {
    items {
      branch = "main"
      connection_type = "DEVOPS_CODE_REPOSITORY"
      name            = "tweet_report_digester_source"
      repository_id   = oci_devops_repository.cloudnative-2021-on-oci-repo.id
      repository_url  = oci_devops_repository.cloudnative-2021-on-oci-repo.http_url  
      ## or use ssh_url ??
      ## "https://devops.scmservice.us-ashburn-1.oci.oraclecloud.com/namespaces/idtwlqf2hanz/projects/cloudnative-2021_devops_project/repositories/cloudnative-2021-on-oci-repo"
    }
  }
  build_spec_file = "/functions/tweet-report-digester/build_spec.yaml"
  description  = ""
  display_name = "build-tweet-report-digester-function-container-image"
  image = "OL7_X86_64_STANDARD_10"
  primary_build_source               = "tweet_report_digester_source"
  stage_execution_timeout_in_seconds = "36000"
}

