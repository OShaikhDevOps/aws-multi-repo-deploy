variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "artifact_bucket_name" {
  type        = string
  description = "Name for S3 artifact bucket (must be globally unique)."
  default     = ""
}

variable "name_prefix" {
  type    = string
  default = "dotnet-cicd"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "pipeline_repo_name" {
  type    = string
  default = "baseRepo"
  description = "Name of the pipeline repository (example: baseRepo)"
}

variable "app_repo_name" {
  type    = string
  default = "Core"
  description = "Name of the application repository (example: Core)"
}

variable "dep_repo_names" {
  type    = list(string)
  default = ["mongo-db", "address-val", "redshift", "oracle", "sql", "polly", "aws-s3", "secret-manager"]
  description = "List of dependency repository names"
}

variable "bitbucket_workspace" {
  type        = string
  description = "Bitbucket workspace (owner/team) used for FullRepositoryId in CodeStar source actions"
  default     = ""
}

variable "codedeploy_application_name" {
  type        = string
  description = "Name of the CodeDeploy application to use in the Deploy action"
  default     = ""
}

variable "codedeploy_deployment_group_name" {
  type        = string
  description = "Name of the CodeDeploy deployment group to use in the Deploy action"
  default     = ""
}
