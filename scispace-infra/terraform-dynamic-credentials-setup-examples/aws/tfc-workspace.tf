# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "tfe" {
  hostname = var.tfc_hostname
}

# Data source used to grab the project under which a workspace will be created.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/project
data "tfe_project" "tfc_project" {
  name         = var.tfc_project_name
  organization = var.tfc_organization_name
}

# Runs in this workspace will be automatically authenticated
# to AWS with the permissions set in the AWS policy.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace
resource "tfe_workspace" "my_workspace" {
  name         = var.tfc_workspace_name
  organization = var.tfc_organization_name
  project_id   = data.tfe_project.tfc_project.id
  working_directory = "tiptap-terraform"

  lifecycle {
    ignore_changes = [
      vcs_repo,
    ]
  }
}

# TF_CLI_ARGS and TF_CLI_ARGS_name
# The value of TF_CLI_ARGS will specify additional arguments to the command-line. This allows easier automation in CI environments as well as modifying default behavior of Terraform on your own system.

# These arguments are inserted directly after the subcommand (such as plan) and before any flags specified directly on the command-line. This behavior ensures that flags on the command-line take precedence over environment variables.

# For example, the following command: TF_CLI_ARGS="-input=false" terraform apply -force is the equivalent to manually typing: terraform apply -input=false -force.

# The flag TF_CLI_ARGS affects all Terraform commands. If you specify a named command in the form of TF_CLI_ARGS_name then it will only affect that command. As an example, to specify that only plans never refresh, you can set TF_CLI_ARGS_plan="-refresh=false".

# The value of the flag is parsed as if you typed it directly to the shell. Double and single quotes are allowed to capture strings and arguments will be separated by spaces otherwise.
resource "tfe_variable" "tfc_terraform_var_file" {
  # Set environment variable to tell TFC to use stage.tfvars as terraform var file
  workspace_id = tfe_workspace.my_workspace.id
  key      = "TF_CLI_ARGS"
  value    = "-var-file=environment/stage.tfvars"
  category = "env"
  description = "The value of TF_CLI_ARGS will specify additional arguments to the command-line. This allows easier automation in CI environments as well as modifying default behavior of Terraform on your own system."
}

# The following variables must be set to allow runs
# to authenticate to AWS.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable
resource "tfe_variable" "enable_aws_provider_auth" {
  workspace_id = tfe_workspace.my_workspace.id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."
}

resource "tfe_variable" "tfc_aws_role_arn" {
  workspace_id = tfe_workspace.my_workspace.id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.tfc_role.arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."
}

# The following variables are optional; uncomment the ones you need!

# resource "tfe_variable" "tfc_aws_audience" {
#   workspace_id = tfe_workspace.my_workspace.id

#   key      = "TFC_AWS_WORKLOAD_IDENTITY_AUDIENCE"
#   value    = var.tfc_aws_audience
#   category = "env"

#   description = "The value to use as the audience claim in run identity tokens"
# }

# The following is an example of the naming format used to define variables for
# additional configurations. Additional required configuration values must also
# be supplied in this same format, as well as any desired optional configuration
# values.
#
# Additional configurations can be used to uniquely authenticate multiple aliases
# of the same provider in a workspace, with different roles/permissions in different
# accounts or regions.
#
# See https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/specifying-multiple-configurations
# for more details on specifying multiple configurations.
#
# See https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration#specifying-multiple-configurations
# for specific requirements and details for the AWS provider.

# resource "tfe_variable" "enable_aws_provider_auth_other_config" {
#   workspace_id = tfe_workspace.my_workspace.id

#   key      = "TFC_AWS_PROVIDER_AUTH_other_config"
#   value    = "true"
#   category = "env"

#   description = "Enable the Workload Identity integration for AWS for an additional configuration named other_config."
# }
