data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "vpc" {
  source               = "telia-oss/vpc/aws"
  version              = "0.2.1"
  name_prefix          = "${var.prefix}"
  cidr_block           = "10.10.0.0/16"
  private_subnet_count = "${var.private_subnet_count}"
  enable_dns_hostnames = "true"
  tags                 = "${var.tags}"
}

module "loadbalancer" {
  source      = "telia-oss/loadbalancer/aws"
  version     = "0.1.1"
  name_prefix = "${var.prefix}"
  type        = "application"
  vpc_id      = "${module.vpc.vpc_id}"
  subnet_ids  = ["${module.vpc.public_subnet_ids}"]
  tags        = "${var.tags}"
}

data "aws_ami" "ecs" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }
}

module "ecs_cluster" {
  source              = "telia-oss/ecs/aws//modules/cluster"
  version             = "0.4.1"
  instance_ami        = "${data.aws_ami.ecs.id}"
  name_prefix         = "${var.prefix}"
  vpc_id              = "${module.vpc.vpc_id}"
  subnet_ids          = ["${module.vpc.private_subnet_ids}"]
  tags                = "${var.tags}"
  load_balancers      = "${module.loadbalancer.security_group_id}"
  load_balancer_count = 1
}

resource "aws_cloudwatch_log_group" "main" {
  name = "${var.prefix}"
}

module "sonarqube-rds" {
  source            = "telia-oss/rds-instance/aws"
  version           = "0.2.0"
  multi_az          = "false"
  name_prefix       = "${var.prefix}"
  username          = "${data.aws_ssm_parameter.sonarqube-rds-username.value}"
  password          = "${data.aws_ssm_parameter.sonarqube-rds-password.value}"
  port              = "5432"
  engine            = "postgres"
  instance_type     = "db.t2.small"
  allocated_storage = "10"
  vpc_id            = "${module.vpc.vpc_id}"
  subnet_ids        = "${module.vpc.private_subnet_ids}"
  tags              = "${var.tags}"
}

data "aws_ssm_parameter" "sonarqube-rds-username" {
  name = "/${var.prefix}/rds-username"
}

resource "aws_ssm_parameter" "sonarqube-rds-url" {
  name      = "/${var.prefix}/rds-url"
  type      = "SecureString"
  value     = "jdbc:postgresql://${module.sonarqube-rds.endpoint}/main"
  overwrite = true

  # tags not supported for aws_ssm_paramter
}

data "aws_ssm_parameter" "sonarqube-rds-password" {
  name = "/${var.prefix}/rds-password"
}

resource "aws_iam_role_policy_attachment" "ssmtotask" {
  policy_arn = "${aws_iam_policy.sonarqube-task-pol.arn}"
  role       = "${aws_iam_role.task-role.name}"

  # tags not supported for aws_iam_role_policy_attachment
}

resource "aws_iam_role" "task-role" {
  name               = "${var.prefix}-task-role"
  assume_role_policy = "${data.aws_iam_policy_document.task-role-policy.json}"
  description        = "limited role for task"

  # tags not supported for aws_iam_role
}

module "sonarqube-service" {
  source               = "telia-oss/ecs/aws//modules/service"
  version              = "0.4.1"
  cluster_id           = "${module.ecs_cluster.id}"
  cluster_role_name    = "${module.ecs_cluster.role_id}"
  health_check {
    port    = "traffic-port"
    path    = "/"
    matcher = "200"
  }
  name_prefix          = "${var.prefix}"
  target {
    protocol      = "HTTP"
    port          = "9000"
    load_balancer = "${module.loadbalancer.arn}"
  }
  task_container_image = "teliaoss/sonarqube-aws-env:7.2.1"
  vpc_id               = "${module.vpc.vpc_id}"
  tags = "${var.tags}"
  task_container_memory_reservation = "1000"
  task_container_environment = {
    "SSM_PARAMETER_NAME_SONARQUBE_JDBC_USERNAME" = "${data.aws_ssm_parameter.sonarqube-rds-username.name}",
    "SSM_PARAMETER_NAME_SONARQUBE_JDBC_PASSWORD" = "${data.aws_ssm_parameter.sonarqube-rds-password.name}",
    "SSM_PARAMETER_NAME_SONARQUBE_JDBC_URL" = "${aws_ssm_parameter.sonarqube-rds-url.name}"
  }
  task_container_environment_count = 3
}

resource "aws_lb_listener" "main" {
  "default_action" {
    target_group_arn = "${module.sonarqube-service.target_group_arn}"
    type = "forward"
  }
  load_balancer_arn = "${module.loadbalancer.arn}"
  port = "443"
}

resource "aws_security_group_rule" "ingress_443" {
  security_group_id = "${module.loadbalancer.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_role_policy_attachment" "kmstotask" {
  policy_arn = "${aws_iam_policy.kmsfortaskpol.arn}"
  role       = "${aws_iam_role.task-role.name}"
}

resource "aws_security_group_rule" "sonarqube_rds_ingress" {
  security_group_id        = "${module.sonarqube-rds.security_group_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "${module.sonarqube-rds.port}"
  to_port                  = "${module.sonarqube-rds.port}"
  source_security_group_id = "${module.ecs_cluster.security_group_id}"
}

data "aws_route53_zone" "aws_route53_zone" {
  name         = "${var.route53_zone}"
  private_zone = false
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${data.aws_route53_zone.aws_route53_zone.id}"
  name    = "${var.prefix}.${data.aws_route53_zone.aws_route53_zone.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.loadbalancer.dns_name}"]
}

module "cluster-agent-policy" {
  source  = "telia-oss/ssm-agent-policy/aws"
  version = "0.1.0"
  name_prefix = "${var.prefix}"
  role   = "${module.ecs_cluster.role_id}"
}
