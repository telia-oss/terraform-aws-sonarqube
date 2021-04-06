terraform {
  required_version = ">= 0.14"

  backend "s3" {
    key            = "terraform-modules/development/terraform-aws-sonarqube/default-init.tfstate"
    bucket         = "<test-account-id>-terraform-state"
    dynamodb_table = "<test-account-id>-terraform-state"
    acl            = "bucket-owner-full-control"
    encrypt        = "true"
    kms_key_id     = "<kms-key-id>"
    region         = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
  allowed_account_ids = ["<test-account-id>"]
}

locals {
  name_prefix = "sonarqube-default-test"

  tags = {
    terraform   = "true"
    environment = "example"
    application = "sonarqube"
  }
}

module "sonarqube-init" {
  name_prefix = local.name_prefix
  source      = "../../../modules/init"
  tags        = local.tags
}

# Don't do this in production - secrets set like this will leak to build logs
resource "aws_ssm_parameter" "sonarqube-github-auth-enabled" {
  name   = "/${local.name_prefix}/github-auth-enabled"
  type   = "SecureString"
  value  = true
  key_id = module.sonarqube-init.parameters_key_arn
}

resource "aws_ssm_parameter" "sonarqube-github-client-id" {
  name   = "/${local.name_prefix}/github-client-id"
  type   = "SecureString"
  value  = "<github-client-id>"
  key_id = module.sonarqube-init.parameters_key_arn
}

resource "aws_ssm_parameter" "sonarqube-github-client-secret" {
  name   = "/${local.name_prefix}/github-client-secret"
  type   = "SecureString"
  value  = "<github-client-secret>"
  key_id = module.sonarqube-init.parameters_key_arn
}

resource "aws_ssm_parameter" "sonarqube-github-organizations" {
  name   = "/${local.name_prefix}/github-organizations"
  type   = "SecureString"
  value  = "<github-organisations>"
  key_id = module.sonarqube-init.parameters_key_arn
}

resource "random_string" "sonarqube-admin-username" {
  length  = 10
  special = false
  number  = false
}

resource "aws_ssm_parameter" "sonarqube-admin-username" {
  name   = "/${local.name_prefix}/admin-username"
  type   = "SecureString"
  value  = random_string.sonarqube-admin-username.result
  key_id = module.sonarqube-init.parameters_key_arn
}

resource "random_string" "sonarqube-admin-password" {
  length  = 10
  special = false
  number  = false
}

resource "aws_ssm_parameter" "sonarqube-admin-password" {
  name   = "/${local.name_prefix}/admin-password"
  type   = "SecureString"
  value  = random_string.sonarqube-admin-password.result
  key_id = module.sonarqube-init.parameters_key_arn
}

output "parameters_key_arn" {
  value = module.sonarqube-init.parameters_key_arn
}

output "parameters_key_alias" {
  value = module.sonarqube-init.parameters_key_alias
}
