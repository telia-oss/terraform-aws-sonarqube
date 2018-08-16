# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "parameters_key_arn" {}

variable "vpc_id" {}

variable "db_subnet_ids" {
  type = "list"
}

variable "loadbalancer_arn" {}

variable "cluster_id" {}

variable "cluster_role_name" {}

variable "cluster_security_group_id" {}

variable "loadbalancer_dns_name" {}

variable "route53_zone" {}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = "map"
  default     = {}
}
