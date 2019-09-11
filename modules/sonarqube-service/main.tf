# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "sonarqube-service" {
  source  = "telia-oss/ecs/aws//modules/service"
  version = "2.0.0"

  name_prefix                       = var.name_prefix
  vpc_id                            = var.vpc_id
  cluster_id                        = var.cluster_id
  cluster_role_name                 = var.cluster_role_name
  task_container_image              = "teliaoss/sonarqube-aws-env:v1.2.2"
  task_container_memory_reservation = 900
  task_container_environment_count  = 11

  health_check = {
    port    = "traffic-port"
    path    = "/"
    matcher = "200"
  }

  target = {
    protocol      = "HTTP"
    port          = 9000
    load_balancer = var.loadbalancer_arn
  }

  task_container_environment = {
    "AWS_REGION"                     = data.aws_region.current.name
    "SONARQUBE_JDBC_USERNAME"        = "ssm://${data.aws_ssm_parameter.sonarqube-rds-username.name}"
    "SONARQUBE_JDBC_PASSWORD"        = "ssm://${data.aws_ssm_parameter.sonarqube-rds-password.name}"
    "SONARQUBE_JDBC_URL"             = "ssm://${aws_ssm_parameter.sonarqube-rds-url.name}"
    "SONARQUBE_BASE_URL"             = "ssm://${aws_ssm_parameter.sonarqube-base-url.name}"
    "SONARQUBE_GITHUB_AUTH_ENABLED"  = "ssm:///${var.name_prefix}/github-auth-enabled"
    "SONARQUBE_GITHUB_CLIENT_ID"     = "ssm:///${var.name_prefix}/github-client-id"
    "SONARQUBE_GITHUB_CLIENT_SECRET" = "ssm:///${var.name_prefix}/github-client-secret"
    "SONARQUBE_GITHUB_ORGANIZATIONS" = "ssm:///${var.name_prefix}/github-organizations"
    "SONARQUBE_ADMIN_USERNAME"       = "ssm:///${var.name_prefix}/admin-username"
    "SONARQUBE_ADMIN_PASSWORD"       = "ssm:///${var.name_prefix}/admin-password"
  }

  tags = var.tags
}

module "sonarqube-rds" {
  source  = "telia-oss/rds-instance/aws"
  version = "3.0.0"

  multi_az            = false
  name_prefix         = var.name_prefix
  username            = data.aws_ssm_parameter.sonarqube-rds-username.value
  password            = data.aws_ssm_parameter.sonarqube-rds-password.value
  port                = 5432
  engine              = "postgres"
  instance_type       = "db.t2.small"
  allocated_storage   = 10
  vpc_id              = var.vpc_id
  subnet_ids          = var.db_subnet_ids
  tags                = var.tags
  skip_final_snapshot = "false"
  snapshot_identifier = var.snapshot_identifier
}

data "aws_ssm_parameter" "sonarqube-rds-username" {
  name = "/${var.name_prefix}/rds-username"
}

data "aws_ssm_parameter" "sonarqube-rds-password" {
  name = "/${var.name_prefix}/rds-password"
}

resource "aws_ssm_parameter" "sonarqube-rds-url" {
  name      = "/${var.name_prefix}/rds-url"
  type      = "SecureString"
  value     = "jdbc:postgresql://${module.sonarqube-rds.endpoint}/main"
  key_id    = var.parameters_key_arn
  overwrite = true
}

resource "aws_ssm_parameter" "sonarqube-base-url" {
  name      = "/${var.name_prefix}/base-url"
  type      = "SecureString"
  value     = "https://${aws_route53_record.sonarqube.fqdn}"
  key_id    = var.parameters_key_arn
  overwrite = true
}

resource "aws_iam_role_policy_attachment" "ssmtotask" {
  policy_arn = aws_iam_policy.sonarqube-task-policy.arn
  role       = module.sonarqube-service.task_role_name
}

resource "aws_iam_role_policy_attachment" "kmstotask" {
  policy_arn = aws_iam_policy.kms-for-task-policy.arn
  role       = module.sonarqube-service.task_role_name
}

resource "aws_security_group_rule" "sonarqube_rds_ingress" {
  security_group_id        = module.sonarqube-rds.security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = module.sonarqube-rds.port
  to_port                  = module.sonarqube-rds.port
  source_security_group_id = var.cluster_security_group_id
}

data "aws_route53_zone" "main" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "sonarqube" {
  zone_id = data.aws_route53_zone.main.id
  name    = "${var.name_prefix}.${data.aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.loadbalancer_dns_name]
}

