terraform {
  required_version = "0.11.11"

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
  version             = "1.52.0"
  region              = "eu-west-1"
  allowed_account_ids = ["<test-account-id>"]
}

locals {
  tags = {
    terraform   = "true"
    environment = "example"
    application = "sonarqube"
  }
}

module "sonarqube-init" {
  name_prefix = "sonarqube"
  source      = "../../../modules/init"
  tags        = "${local.tags}"
}

output "parameters_key_arn" {
  value = "${module.sonarqube-init.parameters_key_arn}"
}
