variable "name_prefix" {
  description = "Typically the name of the application. This value is used as a prefix to the name of most resources created including the public URL"
  type        = string
}

variable "tags" {
  description = "A list of tags that will be applied to resources created that support tagging"
  type        = map(string)
}


variable "cluster_instance_type" {
  description = "The instance type to use for the ECS cluster"
  type        = string
}

variable "cluster_instance_count" {
  description = "The number of EC2 instances to have in the cluster"
  type        = number
}

variable "parameters_key_arn" {
  description = "The arn of the kms key used to encrypt the application parameters stored in SSM"
  type        = string
}

variable "route53_zone_name" {
  description = "The route 53 zone into which this is deployed"
  type        = string
}

variable "snapshot_identifier" {
  description = "The identifier of the snapshot to create the database from - if left empty a new db will be created"
  type        = string
  default     = ""
}

