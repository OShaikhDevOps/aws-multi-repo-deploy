Terraform module scaffold for the CodePipeline/CodeBuild/CodeDeploy wiring.

This folder contains a parameterized skeleton module. It is intentionally minimal and includes placeholders
for resources you should fill (e.g., codebuild buildspecs, artifact bucket naming, CodeStar Connection ARN,
and more restrictive IAM policies).

Important:
- Install and configure the AWS provider and backend as appropriate for your environment.
- Review IAM policies and tighten to least-privilege.
- This module is a starting point and not a drop-in ready solution.

Repository name variables
- `pipeline_repo_name` (default: `baseRepo`)
- `app_repo_name` (default: `Core`)
- `dep_repo_names` (default: `["mongo-db","address-val","redshift","oracle","sql","polly","aws-s3","secret-manager"]`)

These variables are provided in `variables.tf` to keep the Terraform scaffold consistent with the CloudFormation example defaults. Override values when you instantiate the module.
