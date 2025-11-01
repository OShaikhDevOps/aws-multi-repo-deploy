# baseRepo

This repository contains the CI/CD pipeline and infrastructure artifacts that wire a Bitbucket multi-repo pipeline (CodeStar Connection) to CodePipeline, CodeBuild and CodeDeploy to deploy the `Core` .NET 8 Web API to IIS on EC2 instances.

Key artifacts
- `buildspec.yml` - CodeBuild build definition (restore, build, test, Sonar/Trivy placeholders, publish, package)
- `infrastructure/codepipeline-cloudformation.yml` - CloudFormation template to create the pipeline wiring (multi-source CodeStar connections, CodeBuild, CodeDeploy)
- `infrastructure/terraform/` - Terraform scaffold (alternative approach that can support more dynamic generation)
- `infrastructure/cloudformation-parameters.json` - example parameter set used by the included deploy helper
- `infrastructure/deploy-stack.ps1` - PowerShell wrapper that reads the parameters JSON and runs `aws cloudformation deploy`
- `ansible/` - Ansible playbook and role to install the .NET Hosting Bundle on Windows instances
- `appspec.yml` and `scripts/` - CodeDeploy app specification and PowerShell lifecycle hooks used during deployment

Quick start
1. Update `infrastructure/cloudformation-parameters.json` with your Bitbucket workspace and CodeStar Connection ARN. Change the repo names if you use different naming.
2. Ensure you have AWS CLI configured (or pass `-Profile` to the deploy script). From this folder run:

	.\infrastructure\deploy-stack.ps1 -Profile <aws-profile> -Region <aws-region>

3. After CloudFormation creates the CodeStar Connection resource you will need to approve it in the AWS Console (CodeStar Connections) for Bitbucket access.

Architecture diagram

![CI/CD flow](../cicd-flow.png)

Notes
- CloudFormation templates are static and the template currently supports up to 8 dependency repo source slots via parameterized/conditional source actions. For truly dynamic lists consider using the Terraform module in `infrastructure/terraform` or CDK to generate sources programmatically.
- The Terraform scaffold attempts to model the same resources and may be preferable if you want to create a pipeline with a variable number of source repos.

Push this repo to your Bitbucket workspace as `baseRepo` (or set the `PipelineRepoName` parameter accordingly when deploying stacks).
