terraform {
  required_version = "0.11.11"

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
  version             = "1.56.0"
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
  private_subnet_count   = "2"
  cluster_instance_type  = "t2.small"
  cluster_instance_count = "1"
  tags                   = "${local.tags}"
  parameters_key_arn     = "<parameters-key-arn>"
  route53_zone_name      = "<route53-zone-name>"
}

output "sonarqube_URL" {
  value = "${module.sonarqube.sonarqube_url}"
}
