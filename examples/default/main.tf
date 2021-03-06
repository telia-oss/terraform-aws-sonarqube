terraform {
  required_version = ">= 0.14"

  backend "s3" {
    key            = "terraform-modules/development/terraform-aws-sonarqube/default.tfstate"
    bucket         = "<test-account-id>-terraform-state"
    dynamodb_table = "<test-account-id>-terraform-state"
    acl            = "bucket-owner-full-control"
    encrypt        = "true"
    kms_key_id     = "<kms-key-id>"
    region         = "eu-west-1"
  }
}

provider "aws" {
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

module "sonarqube" {
  source                 = "../../"
  name_prefix            = "sonarqube-default-test"
  cluster_instance_type  = "t2.small"
  cluster_instance_count = "1"
  tags                   = local.tags
  parameters_key_arn     = "<parameters_key_arn>"
  route53_zone_name      = "<route53_zone_name>"
}

output "sonarqube_URL" {
  value = module.sonarqube.sonarqube_url
}

