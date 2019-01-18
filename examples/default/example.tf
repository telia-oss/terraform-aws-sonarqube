provider "aws" {
  version = "1.36.0"
  region  = "eu-west-1"
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
  prefix                 = "sonarqube"
  private_subnet_count   = "2"
  cluster_instance_type  = "t2.small"
  cluster_instance_count = "1"
  tags                   = "${local.tags}"
  parameters_key_arn     = "<parameters-key-arn>"
  certificate_arn        = "<certificate-arn>"
  route53_zone           = "<route53-zone>"
}

output "sonarqube_URL" {
  value = "${module.sonarqube.sonarqube_url}"
}
