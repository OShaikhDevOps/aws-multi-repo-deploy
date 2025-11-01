output "artifact_bucket" {
  value       = aws_s3_bucket.artifact_bucket.id
  description = "S3 bucket for pipeline artifacts"
}

output "codebuild_project" {
  value       = aws_codebuild_project.app_build.name
  description = "CodeBuild project name for app build"
}
