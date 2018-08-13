provider "aws" {
  version = "1.30.0"
  region  = "eu-west-1"
}

locals {
  tags = {
    terraform   = "true"
    environment = "example"
    application = "sonarqube"
  }
}

module "sonarqube-init" {
  prefix = "sonarqube"
  source = "../../../standalone/init/"
  tags   = "${local.tags}"
}

output "parameters_key_arn" {
  value = "${module.sonarqube-init.parameters_key_arn}"
}