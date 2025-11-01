terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  # build a list of non-empty repo names (pipeline + app + deps)
  source_repos = [for r in concat([var.pipeline_repo_name, var.app_repo_name], var.dep_repo_names) : r if r != ""]
  branch = "master"
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = var.artifact_bucket_name
  force_destroy = true
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = var.tags
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.name_prefix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.name_prefix}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions = ["s3:GetObject", "s3:PutObject", "s3:GetObjectVersion"]
    resources = ["${aws_s3_bucket.artifact_bucket.arn}/*"]
  }
}

resource "aws_codebuild_project" "app_build" {
  name = "${var.name_prefix}-app-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image = "aws/codebuild/windows-base:latest"
    type = "WINDOWS_CONTAINER"
    environment_variable {
      name  = "BUILD_CONFIGURATION"
      value = "Release"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}

# CodeStar Connection (this creates a connection object which must be approved in the console)
resource "aws_codestarconnections_connection" "bitbucket_connection" {
  name = "${var.name_prefix}-bitbucket-connection"
  provider_type = "Bitbucket"
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.name_prefix}-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.name_prefix}-pipeline-policy"
  role = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    actions = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
    resources = ["${aws_s3_bucket.artifact_bucket.arn}/*"]
  }
  statement {
    actions = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
    resources = ["*"]
  }
}

resource "aws_codepipeline" "pipeline" {
  name = "${var.name_prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type = "S3"
    location = aws_s3_bucket.artifact_bucket.bucket
  }

  # Source stage: one action per repo in local.source_repos
  stage {
    name = "Source"

    dynamic "action" {
      for_each = local.source_repos
      content {
        name     = replace(action.value, "-", "_")
        category = "Source"
        owner    = "AWS"
        provider = "CodeStarSourceConnection"
        version  = "1"

        configuration = {
          ConnectionArn    = aws_codestarconnections_connection.bitbucket_connection.arn
          FullRepositoryId = "${var.bitbucket_workspace}/${action.value}"
          BranchName       = local.branch
        }

        output_artifacts = [{ name = "${replace(action.value, "-", "_")}Output" }]

        run_order = 1
      }
    }
  }

  # Build stage: single CodeBuild project consuming all source outputs
  stage {
    name = "Build"
    action {
      name     = "AppBuild"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }

      input_artifacts  = [for r in local.source_repos : "${replace(r, "-", "_")}Output"]

      output_artifacts = [{ name = "BuildOutput" }]

      run_order = 1
    }
  }

  # Prep stage (optional): placeholder CodeBuild action for Ansible or other prep work
  stage {
    name = "Prep"
    action {
      name     = "AnsiblePrep"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }

      input_artifacts = [for r in local.source_repos : "${replace(r, "-", "_")}Output"]

      output_artifacts = [{ name = "PrepOutput" }]

      run_order = 1
    }
  }

  # Deploy stage: CodeDeploy action (user must supply names via variables)
  stage {
    name = "Deploy"
    action {
      name     = "CodeDeployAction"
      category = "Deploy"
      owner    = "AWS"
      provider = "CodeDeploy"
      version  = "1"

      configuration = {
        ApplicationName     = var.codedeploy_application_name
        DeploymentGroupName = var.codedeploy_deployment_group_name
      }

      input_artifacts = ["BuildOutput"]
      run_order = 1
    }
  }
}
