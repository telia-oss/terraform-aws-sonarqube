# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------

output "target_group_arn" {
  value = "${module.sonarqube-service.target_group_arn}"
}

output "sonarqube_url" {
  value = "https://${aws_route53_record.sonarqube.fqdn}"
}
