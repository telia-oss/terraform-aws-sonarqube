provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
}

locals {
  name_prefix = "sonarqube-example"

  tags = {
    terraform   = "true"
    environment = "example"
    application = "sonarqube"
  }
}

module "ecs_cluster" {
  source              = "telia-oss/ecs/aws//modules/cluster"
  version             = "0.4.1"
  instance_ami        = "ami-0af844a965e5738db"
  instance_type       = "t2.small"
  name_prefix         = "${local.name_prefix}"
  vpc_id              = "${data.aws_vpc.main.id}"
  subnet_ids          = ["${data.aws_subnet_ids.main.ids}"]
  tags                = "${local.tags}"
  load_balancers      = ["${module.loadbalancer.security_group_id}"]
  load_balancer_count = 1
}

module "loadbalancer" {
  source      = "telia-oss/loadbalancer/aws"
  version     = "0.1.1"
  name_prefix = "${local.name_prefix}"
  type        = "application"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${data.aws_subnet_ids.main.ids}"]
  tags        = "${local.tags}"
}

module "sonarqube" {
  source                    = "../"
  name_prefix               = "${local.name_prefix}"
  vpc_id                    = "${data.aws_vpc.main.id}"
  db_subnet_ids             = "${data.aws_subnet_ids.main.ids}"
  parameters_key_arn        = "${local.parameters_key_arn}"
  loadbalancer_arn          = "${module.loadbalancer.arn}"
  cluster_id                = "${module.ecs_cluster.id}"
  cluster_role_name         = "${module.ecs_cluster.role_name}"
  cluster_security_group_id = "${module.ecs_cluster.security_group_id}"
  loadbalancer_dns_name     = "${module.loadbalancer.dns_name}"
  route53_zone              = "${var.route53_zone}"
}
