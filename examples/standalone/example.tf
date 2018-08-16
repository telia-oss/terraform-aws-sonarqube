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

module "sonarqube" {
  source                 = "../../standalone/"
  prefix                 = "sonarqube"
  private_subnet_count   = "2"
  cluster_instance_type  = "t2.small"
  cluster_instance_count = "1"
  tags                   = "${local.tags}"
  parameters_key_arn     = "arn:aws:kms:eu-west-1:951215386089:key/856bf1f0-6eba-4c43-b48f-9bb84dff54db"
  certificate_arn        = "arn:aws:acm:eu-west-1:951215386089:certificate/094ffda3-b8cc-43ef-9e6f-b10b38d81dce"
  route53_zone           = "common-services-stage.telia.io"
}

output "sonarqube_URL" {
  value = "${module.sonarqube.sonarqube_URL}"
}
