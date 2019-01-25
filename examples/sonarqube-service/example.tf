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
  name_prefix     = "sonarqube-example"
  route53_zone    = "example.com"
  certificate_arn = "<ssl-certificate-arn>"

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
  source                    = "../../modules/sonarqube-service"
  name_prefix               = "${local.name_prefix}"
  vpc_id                    = "${data.aws_vpc.main.id}"
  db_subnet_ids             = "${data.aws_subnet_ids.main.ids}"
  parameters_key_arn        = "${aws_kms_key.sonarqube-parameters.arn}"
  loadbalancer_arn          = "${module.loadbalancer.arn}"
  cluster_id                = "${module.ecs_cluster.id}"
  cluster_role_name         = "${module.ecs_cluster.role_name}"
  cluster_security_group_id = "${module.ecs_cluster.security_group_id}"
  loadbalancer_dns_name     = "${module.loadbalancer.dns_name}"
  route53_zone_name         = "${local.route53_zone}"
}

resource "aws_lb_listener" "main" {
  "default_action" {
    target_group_arn = "${module.sonarqube.target_group_arn}"
    type             = "forward"
  }

  load_balancer_arn = "${module.loadbalancer.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${local.certificate_arn}"
}

resource "aws_security_group_rule" "ingress_443" {
  security_group_id = "${module.loadbalancer.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_kms_key" "sonarqube-parameters" {
  description = "KMS key for encrypting parameters passed to sonarqube."
  tags        = "${local.tags}"
}

resource "aws_kms_alias" "key-alias" {
  name          = "alias/${local.name_prefix}-parameters"
  target_key_id = "${aws_kms_key.sonarqube-parameters.id}"
}

#Passwords set and storted in repo for example only (don't do it this way!)
resource "aws_ssm_parameter" "rds_username" {
  name   = "/${local.name_prefix}/rds-username"
  type   = "SecureString"
  value  = "username"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}

resource "aws_ssm_parameter" "rds_password" {
  name   = "/${local.name_prefix}/rds-password"
  type   = "SecureString"
  value  = "notsogoodpassword"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}

resource "aws_ssm_parameter" "admin_username" {
  name   = "/${local.name_prefix}/admin-username"
  type   = "SecureString"
  value  = "admin"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}

resource "aws_ssm_parameter" "admin_password" {
  name   = "/${local.name_prefix}/admin-username"
  type   = "SecureString"
  value  = "anotherbadpassword"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}

resource "aws_ssm_parameter" "github-auth-enabled" {
  name   = "/${local.name_prefix}/github-auth-enabled"
  type   = "SecureString"
  value  = "true"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}

resource "aws_ssm_parameter" "github-client-id" {
  name   = "/${local.name_prefix}/github-client-id"
  type   = "SecureString"
  value  = "<id-from-github>"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}

resource "aws_ssm_parameter" "github-client-secret" {
  name   = "/${local.name_prefix}/github-client-secret"
  type   = "SecureString"
  value  = "<secret-from-github>"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}

resource "aws_ssm_parameter" "github-organizations" {
  name   = "/${local.name_prefix}/github-organizations"
  type   = "SecureString"
  value  = "<github-organization>"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}
