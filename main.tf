# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "sonarqube-service" {
  source            = "telia-oss/ecs/aws//modules/service"
  version           = "0.4.1"
  cluster_id        = "${var.cluster_id}"
  cluster_role_name = "${var.cluster_role_name}"

  health_check {
    port    = "traffic-port"
    path    = "/"
    matcher = "200"
  }

  name_prefix = "${var.name_prefix}"

  target {
    protocol      = "HTTP"
    port          = "9000"
    load_balancer = "${var.loadbalancer_arn}"
  }

  task_container_image              = "teliaoss/sonarqube-aws-env:7.3"
  vpc_id                            = "${var.vpc_id}"
  tags                              = "${var.tags}"
  task_container_memory_reservation = "1000"

  task_container_environment = {
    "SONARQUBE_JDBC_USERNAME"        = "ssm://${data.aws_ssm_parameter.sonarqube-rds-username.name}"
    "SONARQUBE_JDBC_PASSWORD"        = "ssm://${data.aws_ssm_parameter.sonarqube-rds-password.name}"
    "SONARQUBE_JDBC_URL"             = "ssm://${aws_ssm_parameter.sonarqube-rds-url.name}"
    "SONARQUBE_BASE_URL"             = "ssm://${aws_ssm_parameter.sonarqube-base-url.name}"
    "SONARQUBE_GITHUB_AUTH_ENABLED"  = "ssm://${data.aws_ssm_parameter.sonarqube-github-auth-enabled.name}"
    "SONARQUBE_GITHUB_CLIENT_ID"     = "ssm://${data.aws_ssm_parameter.sonarqube-github-client-id.name}"
    "SONARQUBE_GITHUB_CLIENT_SECRET" = "ssm://${data.aws_ssm_parameter.sonarqube-github-client-secret.name}"
    "SONARQUBE_GITHUB_ORGANIZATIONS" = "ssm://${data.aws_ssm_parameter.sonarqube-github-organizations.name}"
    "SONARQUBE_ADMIN_USERNAME"       = "ssm://${data.aws_ssm_parameter.sonarqube-admin-username.name}"
    "SONARQUBE_ADMIN_PASSWORD"       = "ssm://${data.aws_ssm_parameter.sonarqube-admin-password.name}"
  }

  task_container_environment_count = 10
}

module "sonarqube-rds" {
  source            = "telia-oss/rds-instance/aws"
  version           = "0.2.0"
  multi_az          = "false"
  name_prefix       = "${var.name_prefix}"
  username          = "${data.aws_ssm_parameter.sonarqube-rds-username.value}"
  password          = "${data.aws_ssm_parameter.sonarqube-rds-password.value}"
  port              = "5432"
  engine            = "postgres"
  instance_type     = "db.t2.small"
  allocated_storage = "10"
  vpc_id            = "${var.vpc_id}"
  subnet_ids        = "${var.db_subnet_ids}"
  tags              = "${var.tags}"
}

data "aws_ssm_parameter" "sonarqube-rds-username" {
  name = "/${var.name_prefix}/rds-username"
}

data "aws_ssm_parameter" "sonarqube-rds-password" {
  name = "/${var.name_prefix}/rds-password"
}

data "aws_ssm_parameter" "sonarqube-github-auth-enabled" {
  name = "/${var.name_prefix}/github-auth-enabled"
}

data "aws_ssm_parameter" "sonarqube-github-client-id" {
  name = "/${var.name_prefix}/github-client-id"
}

data "aws_ssm_parameter" "sonarqube-github-client-secret" {
  name = "/${var.name_prefix}/github-client-secret"
}

data "aws_ssm_parameter" "sonarqube-github-organizations" {
  name = "/${var.name_prefix}/github-organizations"
}

data "aws_ssm_parameter" "sonarqube-admin-username" {
  name = "/${var.name_prefix}/admin-username"
}

data "aws_ssm_parameter" "sonarqube-admin-password" {
  name = "/${var.name_prefix}/admin-password"
}

resource "aws_ssm_parameter" "sonarqube-rds-url" {
  name      = "/${var.name_prefix}/rds-url"
  type      = "SecureString"
  value     = "jdbc:postgresql://${module.sonarqube-rds.endpoint}/main"
  key_id    = "${var.parameters_key_arn}"
  overwrite = true
}

resource "aws_ssm_parameter" "sonarqube-base-url" {
  name      = "/${var.name_prefix}/base-url"
  type      = "SecureString"
  value     = "https://${aws_route53_record.sonarqube.fqdn}"
  key_id    = "${var.parameters_key_arn}"
  overwrite = true
}

resource "aws_iam_role_policy_attachment" "ssmtotask" {
  policy_arn = "${aws_iam_policy.sonarqube-task-policy.arn}"
  role       = "${module.sonarqube-service.task_role_name}"
}

resource "aws_iam_role_policy_attachment" "kmstotask" {
  policy_arn = "${aws_iam_policy.kms-for-task-policy.arn}"
  role       = "${module.sonarqube-service.task_role_name}"
}

resource "aws_security_group_rule" "sonarqube_rds_ingress" {
  security_group_id        = "${module.sonarqube-rds.security_group_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "${module.sonarqube-rds.port}"
  to_port                  = "${module.sonarqube-rds.port}"
  source_security_group_id = "${var.cluster_security_group_id}"
}

data "aws_route53_zone" "aws_route53_zone" {
  name         = "${var.route53_zone}"
  private_zone = false
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${data.aws_route53_zone.aws_route53_zone.id}"
  name    = "${var.name_prefix}.${data.aws_route53_zone.aws_route53_zone.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.loadbalancer_dns_name}"]
}
