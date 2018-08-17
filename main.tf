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
  instance_type       = "t2.small"
  name_prefix         = "${var.prefix}"
  vpc_id              = "${module.vpc.vpc_id}"
  subnet_ids          = ["${module.vpc.private_subnet_ids}"]
  tags                = "${var.tags}"
  load_balancers      = ["${module.loadbalancer.security_group_id}"]
  load_balancer_count = 1
}

module "sonarqube_service" {
  source                    = "modules/sonarqube-service"
  name_prefix               = "${var.prefix}"
  vpc_id                    = "${module.vpc.vpc_id}"
  db_subnet_ids             = "${module.vpc.private_subnet_ids}"
  parameters_key_arn        = "${var.parameters_key_arn}"
  loadbalancer_arn          = "${module.loadbalancer.arn}"
  cluster_id                = "${module.ecs_cluster.id}"
  cluster_role_name         = "${module.ecs_cluster.role_name}"
  cluster_security_group_id = "${module.ecs_cluster.security_group_id}"
  loadbalancer_dns_name     = "${module.loadbalancer.dns_name}"
  route53_zone              = "${var.route53_zone}"
}

resource "aws_lb_listener" "main" {
  "default_action" {
    target_group_arn = "${module.sonarqube_service.target_group_arn}"
    type             = "forward"
  }

  load_balancer_arn = "${module.loadbalancer.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.certificate_arn}"
}

resource "aws_security_group_rule" "ingress_443" {
  security_group_id = "${module.loadbalancer.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "cluster-agent-policy" {
  source      = "telia-oss/ssm-agent-policy/aws"
  version     = "0.1.0"
  name_prefix = "${var.prefix}"
  role        = "${module.ecs_cluster.role_name}"
}
